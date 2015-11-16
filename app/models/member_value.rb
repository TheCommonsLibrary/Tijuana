class MemberValue < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_activity_event
  belongs_to :financial_transaction, class_name: "Transaction", foreign_key: :transaction_id

  PRIORITY = 20

  # Retrieves the current member values as a hash of symbols
  def self.current_values_for_user(user)
    values = {}
    current_values = where(user_id: user.id, current: true)
    return {} if current_values.empty?
    [:money, :voice, :time].each do |type|
      values[type] = current_values.detect { |value| value.value_type == type }
      .try(:cumulative_value) || 0
    end
    values
  end

  def value_type
    read_attribute(:value_type).to_sym
  end

  # Recalculate the member value for a user in a delayed job
  def self.queue_recalculate_for_user(user, activity, content_module, page, event)
    return unless Rails.configuration.recalculate_member_value_after_action

    return MemberValue.delay(priority: PRIORITY).recalculate_money_value(user) if self.money_value_action_taken?(activity, content_module)
    return MemberValue.delay(priority: PRIORITY).recalculate_voice_value(user) if self.voice_value_action_taken?(activity, content_module, page)
    return MemberValue.delay(priority: PRIORITY).recalculate_time_value(user) if self.time_value_action_taken?(activity, content_module, page, event)
  end

  def self.with_logging(level)
    begin
      old_level = Rails.logger.level
      Rails.logger.level = level
      yield
    ensure
      Rails.logger.level = old_level
    end
  end

  # ensure all the modules are loaded first
  Dir[Rails.root + 'app/models/*_module.rb'].each do |file|
    require file unless Object.const_defined?(File.basename(file, ".rb").classify)
  end
  def self.voice_modules
    Object.constants
      .grep(/.+Module$/)
      .map{ |c| c.to_s.constantize }
      .select{ |c| c.class == Class }
      .map(&:new)
      .select{ |o| o.respond_to?(:member_value_voice_module?) }
      .select(&:member_value_voice_module?)
      .map(&:class)
      .map(&:to_s)
  rescue ActiveRecord::StatementInvalid => e
    return [] if Rails.env.development? # ignore in dev
    raise # raise in prod/showcase
  end
  VOICE_MODULES = self.voice_modules

  # Calculates voice value based:
  #  * actions with from content modules defined in `VOICE_MODULES`
  def self.recalculate_voice_value(user)
    self.with_logging(Logger::INFO) do
      self.log_job_details user.id, 'voice'

      voice_events = UserActivityEvent.joins(:page)
        .where(user_id: user.id)
        .where('activity in (?)', ['external_action', 'action_taken'])
        .where("( (pages.member_value_type = 'voice') AND (content_module_type <> 'DonationModule') ) OR " +
          "(content_module_type IN (?) AND (pages.member_value_type = '' OR pages.member_value_type IS NULL) )", VOICE_MODULES)
        .order(:created_at)

      cumulative_value = 0
      # updates a record for this user activity event if none exists create a record
      records = voice_events.map { |event|
        cumulative_value += 1
        current_record = where(user_activity_event_id: event.id).first()
        if current_record
          current_record.update_attributes!(cumulative_value: cumulative_value, delta_value: 1, value_type: :voice)
          current_record.save! if current_record.changed?
        else
          current_record = create!(user: user, value_type: :voice, created_at: event.created_at,
                                   user_activity_event: event,
                                   delta_value: 1, cumulative_value: cumulative_value,
                                   campaign_id: event.campaign_id, page_id: event.page_id
          )
        end
        current_record
      }
      reset_current_and_cleanup(user, records, :voice)
    end
  end

  # Calculates money value based:
  #  * successful and not refunded transactions
  def self.recalculate_money_value(user)
    self.with_logging(Logger::INFO) do
      self.log_job_details user.id, 'money'
      # find all successful, not refunded, not flagged and positive transactions for this user
      transactions = Transaction
        .includes(:donation)
        .where(successful: true, refunded: false, refund_of_id: nil)
        .where('donations.user_id' => user.id)
        .where('transactions.amount_in_cents > 0')
        .order('transactions.created_at')
      # ensure there is a member value record for each transaction
      cumulative_value = 0
      records = transactions.map { |transaction|
        current_record = where(transaction_id: transaction.id).first()
        cumulative_value += transaction.amount_in_cents
        if current_record
          current_record.update_attributes!(cumulative_value: cumulative_value, delta_value: transaction.amount_in_cents, value_type: :money)
          current_record.save! if current_record.changed?
        else
          current_record = create!(user: user, value_type: :money, created_at: transaction.created_at,
                                   financial_transaction: transaction,
                                   delta_value: transaction.amount_in_cents, cumulative_value: cumulative_value,
                                   campaign_id: transaction.donation.page.try(:page_sequence).try(:campaign_id),
                                   page_id: transaction.donation.page_id
          )
        end
        current_record
      }
      reset_current_and_cleanup(user, records, :money)
    end
  end

  # Calculates time value based:
  #  * get together events
  #  * external actions against pages with value_type == 'time'
  #  * CallMPModule
  def self.recalculate_time_value(user)
    self.with_logging(Logger::INFO) do
      self.log_job_details user.id, 'time'

      time_events = UserActivityEvent.joins('LEFT OUTER JOIN pages ON pages.id = user_activity_events.page_id')
        .where(user_id: user.id)
        .where('activity in (?)', ['external_action', 'action_taken'])
        .where("( (pages.member_value_type = 'time') AND (content_module_type <> 'DonationModule') )" +
               " OR (get_together_event_id IS NOT NULL)" +
               " OR (content_module_type = 'CallMPModule' AND (pages.member_value_type = '' OR pages.member_value_type IS NULL) )")
        .order(:created_at)

      cumulative_value = 0
      # update a record for this user activity event, if none exists create a new record
      records = time_events.map { |event|
        cumulative_value += 1
        current_record = where(user_activity_event_id: event.id).first()
        if current_record
          current_record.update_attributes!(cumulative_value: cumulative_value, delta_value: 1, value_type: :time)
          current_record.save! if current_record.changed?
        else
          current_record = create!(user: user, value_type: :time, created_at: event.created_at,
                                   user_activity_event: event,
                                   delta_value: 1, cumulative_value: cumulative_value,
                                   campaign_id: get_campaign_id_for_event(event), page_id: event.page_id
          )
        end
        current_record
      }
      reset_current_and_cleanup(user, records, :time)
    end
  end

  protected

  # Set the current i.e. most recent record + remove any records weren't
  # calculated for this type
  def self.reset_current_and_cleanup(user, records, type)
    # reset the current event
    current_record = records.last
    old_current_record = where(user_id: user.id, value_type: type, current: true).first()
    if current_record != old_current_record
      old_current_record.update_attributes!(current: false) if old_current_record
      current_record.update_attributes!(current: true) if current_record
    end
    # clear out unknown records for this user
    where(user_id: user.id, value_type: type)
    .where(arel_table[:id].not_in records.map(&:id))
    .delete_all
  end

  # Attempt to extract the campaign id from the user activity event itself,
  # otherwise fallback to trying the get together
  def self.get_campaign_id_for_event(event)
    event.campaign_id ||
        event.try(:get_together_event).try(:get_together).try(:campaign_id)
  end

private

  def self.money_value_action_taken?(activity, content_module)
    action_taken?(activity) && member_value_type_money?(content_module)
  end

  def self.voice_value_action_taken?(activity, content_module, page)
    any_action_taken?(activity) && (page_value_type_voice?(page) || member_value_type_voice?(page, content_module))
  end

  def self.time_value_action_taken?(activity, content_module, page, event)
    any_action_taken?(activity) && (page_value_type_time?(page) || member_value_type_time?(page, content_module, event))
  end

  def self.action_taken?(activity)
    activity == UserActivityEvent::Activity::ACTION_TAKEN
  end

  def self.page_value_type_time?(page)
    page &&  page.member_value_type == 'time'
  end

  def self.page_value_type_voice?(page)
    page &&  page.member_value_type == 'voice'
  end

  def self.page_value_type_blank?(page)
    page && page.member_value_type.blank?
  end

  def self.member_value_type_voice?(page, content_module)
    page_value_type_blank?(page) && content_module && content_module.member_value_voice_module?
  end

  def self.member_value_type_money?(content_module)
    content_module && content_module.member_value_money_module?
  end

  def self.member_value_type_time?(page, content_module, event)
    event || (page_value_type_blank?(page) && content_module && content_module.member_value_time_module?)
  end

  def self.any_action_taken?(activity)
    [UserActivityEvent::Activity::EXTERNAL_ACTION, UserActivityEvent::Activity::ACTION_TAKEN].include?(activity)
  end
  
  def self.log_job_details(user_id, value_type)
    Rails.logger.info "Recalculating #{value_type} value for user id #{user_id}"
  end
end
