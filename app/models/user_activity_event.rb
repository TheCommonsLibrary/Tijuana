class UserActivityEvent < ActiveRecord::Base
  extend ActionView::Helpers::TextHelper

  belongs_to :user
  belongs_to :campaign
  belongs_to :page_sequence
  belongs_to :page
  belongs_to :email
  belongs_to :get_together_event, :class_name => "Event"
  belongs_to :push
  belongs_to :content_module
  belongs_to :user_response, :polymorphic => true
  belongs_to :acquisition_source
  
  before_save :denormalize
  after_save :recalculate_member_value

  module Activity
    ACTION_TAKEN = :action_taken
    EXTERNAL_ACTION = :external_action
    SUBSCRIBED = :subscribed
    EMAIL_CLICKED = :email_clicked
    EMAIL_VIEWED = :email_viewed
    EMAIL_SENT = :email_sent
    EMAIL_DROPPED = :email_dropped
    QUARANTINED = :quarantined
    UNQUARANTINED = :unquarantined
    UNSUBSCRIBED = :unsubscribed
    AGRA_UNSUBSCRIBED = :agra_unsubscribed
    REQUESTED_LESS_EMAIL = :requested_less_email
    OPT_OUT_ONE_CLICK = :opt_out_one_click
  end

  scope :actions_taken, -> { where(:activity => Activity::ACTION_TAKEN) }
  scope :subscriptions, -> { where(:activity => Activity::SUBSCRIBED) }
  scope :unsubscriptions, -> { where(:activity => Activity::UNSUBSCRIBED) }

  scope :emails_sent, -> { where(:activity => Activity::EMAIL_SENT) }
  scope :emails_viewed, -> { where(:activity => Activity::EMAIL_VIEWED) }
  scope :emails_clicked, -> { where(:activity => Activity::EMAIL_CLICKED) }
  scope :email_drops, -> { where(:activity => Activity::EMAIL_DROPPED) }

  scope :quarantines, -> { where(:activity => Activity::QUARANTINED) }
  scope :unquarantines, -> { where(:activity => Activity::UNQUARANTINED) }

  def activity
    read_attribute(:activity).to_sym
  end
  
  def is_action?
    self.activity == Activity::ACTION_TAKEN || self.activity == Activity::EXTERNAL_ACTION
  end

  def self.subscribed!(user, page=nil, content_module=nil, email=nil, source=nil, acquisition_source=nil)
    create!(
            :activity => Activity::SUBSCRIBED,
            :user => user,
            :public_stream_html => "<span class=\"name\">#{user.greeting || 'A new member'}</span> subscribed to GetUp!",
            :content_module => content_module,
            :email => email,
            :page => page,
            :source => source,
            :acquisition_source => acquisition_source
            )
  end
  
  def self.subcribe_user_created_by_nb!(user)
    create!(
            :activity => Activity::SUBSCRIBED,
            :user => user,
            :public_stream_html => "<span class=\"name\">#{user.greeting || 'A new member'}</span> created by Nation Builder",
            :source => 'nb'
            )
  end

  def self.action_taken!(user, page, content_module, user_response, email, source=nil, acquisition_source=nil)
    create!(
            :activity => Activity::ACTION_TAKEN,
            :user => user,
            :content_module => content_module,
            :page => page,
            :user_response => user_response,
            :email => email,
            :source => source,
            :public_stream_html => content_module.public_activity_stream_html(user, page),
            :acquisition_source => acquisition_source
            )
  end

  # record external actions such as Survey response or Field action against a relevant page
  def self.external_action!(user_id, page)
    create!(:activity => Activity::EXTERNAL_ACTION,
            :public_stream_html => "A member took action for #{page.name}",
            :user_id => user_id,
            :page => page)
  end

  def self.email_clicked!(user, email)
    Push.log_activity!(:email_clicked, user, email)
  end


  def self.email_viewed!(user, email)
    Push.log_activity!(:email_viewed, user, email)
  end
  
  def self.registered_to_host!(user, get_together_event)
    create!(
            :activity => Activity::ACTION_TAKEN,
            :user => user,
            :get_together_event => get_together_event,
            :public_stream_html => "<span class=\"name\">#{user.greeting || 'A friend'}</span> is hosting " \
              "<a href=\"#{Rails.application.routes.url_helpers.event_path get_together_event.friendly_id}\">#{self.truncate(get_together_event.name, length: 40)}</a>"
            )
  end

  def self.registered_create_event_from_email!(user, get_together_event, email)
    create!(
            :activity => Activity::ACTION_TAKEN,
            :user => user,
            :email => email,
            :get_together_event => get_together_event
            )
  end

  def self.registered_to_attend!(user, get_together_event, email, acquisition_source=nil)
    create!(
            :activity => Activity::ACTION_TAKEN,
            :user => user,
            :email => email,
            :get_together_event => get_together_event,
            :public_stream_html => "<span class=\"name\">#{user.greeting || 'A friend'}</span> is attending " \
              "<a href=\"#{Rails.application.routes.url_helpers.event_path get_together_event.friendly_id}\">#{self.truncate(get_together_event.name, length: 40)}</a>",
            :acquisition_source => acquisition_source
            )
  end

  def self.agra_unsubscribed!(user, response, email=nil)
    create!(
      :activity => Activity::AGRA_UNSUBSCRIBED,
      :user => user,
      :email => email,
      :user_response => response,
      :public_stream_html => "<span class=\"name\">#{user.greeting || 'Member'}</span> updated their subscription."
    )
  end

  def self.agra_take_action!(user, email, response, acquisition_source=nil)
    html = "<span class=\"name\">#{user.greeting || 'Member'}</span> #{response.action_desc} Community Run campaign <a href='#{response.campaign_url}'></a>"
    html = html.sub("></a>", ">#{truncate(response.campaign_name, :length => 255-html.length)}</a>")

    create!(
      :activity => Activity::ACTION_TAKEN,
      :user => user,
      :campaign => email ? email.blast.push.campaign : nil,
      :user_response => response,
      :email => email,
      :push => email ? email.blast.push : nil,
      :source => "cr_#{response.role}",
      :public_stream_html => html,
      acquisition_source: acquisition_source
    )
  end

  def self.unsubscribed!(user, response, email=nil)
    create!(
      :activity => Activity::UNSUBSCRIBED,
      :user => user,
      :email => email,
      :user_response => response,
      :public_stream_html => "<span class=\"name\">#{user.greeting || 'Member'}</span> updated their subscription."
    )
  end

  def self.requested_less_email!(user, email=nil)
    create!(
      :activity => Activity::REQUESTED_LESS_EMAIL,
      :user => user,
      :email => email,
      :public_stream_html => "<span class=\"name\">#{user.greeting || 'Member'}</span> updated their subscription."
    )
  end

  def self.email_dropped_unless_duplicate_event!(user, source, dropped_at)
    email_dropped!(user, source, dropped_at) unless
      email_drops.where(created_at: dropped_at, user_id: user.id, source: "sg_#{source}").exists?
  end

  def self.email_dropped!(user, source, dropped_at)
    create!(
      :created_at => dropped_at,
      :activity => Activity::EMAIL_DROPPED,
      :user => user,
      :source => "sg_#{source}",
      :public_stream_html => "<span class=\"name\">#{user.greeting || 'Member'}</span> updated their subscription."
    )
  end

  def self.quarantined!(user, email=nil, page=nil, source=nil, agra_action=nil)
    create!(
      activity: Activity::QUARANTINED,
      user: user,
      email: email,
      page: page,
      source: source,
      user_response: agra_action,
      :public_stream_html => "<span class=\"name\">#{user.greeting || 'Member'}</span> updated their subscription."
    )
  end

  def self.unquarantined!(user, source=nil, user_activity_event=nil)
    create!(
      user: user,
      activity: Activity::UNQUARANTINED,
      source: source,
      user_response: user_activity_event,
      :public_stream_html => "<span class=\"name\">#{user.greeting || 'Member'}</span> updated their subscription."
    )
  end

  def self.opted_out_of_one_click!(user, page)
    create!(
      user: user,
      page: page,
      activity: Activity::OPT_OUT_ONE_CLICK,
      public_stream_html: "<span class=\"name\">#{user.greeting || 'Member'}</span> updated their subscription."
    )
  end

  protected

  def recalculate_member_value
    if user && is_action?
      MemberValue.queue_recalculate_for_user(user, self.activity, self.content_module, self.page, self.get_together_event)
    end
  end

  private

  def denormalize
    if content_module
      self.content_module_type = content_module.class.name
    end
    if page
      self.page_sequence = page.page_sequence
      self.campaign = page_sequence.campaign
    end
  end
end
