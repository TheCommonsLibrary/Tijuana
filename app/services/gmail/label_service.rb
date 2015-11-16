require 'googleauth'
require 'google/apis/gmail_v1'
GmailApi = Google::Apis::GmailV1 unless defined?(GmailApi)

class Gmail::LabelService

  # Handle label_new_messages_if_not_scheduled and label_volunteer_messages_if_not_scheduled
  def self.method_missing(method)
    if match = method.to_s.match(/(label_new_messages|label_volunteer_messages)_if_not_scheduled/)
      delay_method = match[1]
      delay.send(delay_method.to_sym) unless already_a_job?(delay_method)
    else
      super
    end
  end

  def self.label_new_messages
    label_messages(AppConstants.gmail_account) do |member, message|
      determine_member_labels(member) | determine_email_labels(message)
    end
  end

  def self.label_volunteer_messages
    label_messages(AppConstants.volunteer_gmail_account) do |member, message|
      if member && member.postcode && (electorate = member.postcode.electorates.most_likely_federal.first)
        labels = ["electorates/#{electorate.name.downcase}"]
      else
        labels = ['unknown electorate']
      end
      member.merge_tags!(labels | ['electorate_volunteer']) if member
      labels
    end
  end

  def self.max_attempts
    5
  end

  protected

  def self.label_messages(account)
    ExceptionNotifier.rescue_and_mail_tech do
      gmail = Gmail::Client.get_client(account)
      messages = gmail.list_user_messages('me', label_ids: ['INBOX'], q: '-label:processed newer_than:1d').messages
      return unless messages
      messages.each do |message_summary|
        message_id = message_summary.id
        message = gmail.get_user_message('me', message_id)
        raise "unable to find message #{message_id}" unless message
        member = member_that_sent_message(message)
        labels = member && member.email =~ /@getup.org.au/ ? [] : yield(member, message)
        labels.push('processed')
        create_and_modify_labels_on_message(gmail, message_id, labels)
      end
    end
  end

  def self.member_that_sent_message(message)
    from_header = extract_header(message, 'From')
    return unless from_header
    email_match = from_header.match(/\b(\S+@\S+)\b/)
    return unless email_match
    email = email_match[0]
    User.find_by_email(email)
  end

  def self.determine_member_labels(member)
    return [] unless member
    %w[donor middle-donor recurring active primary].select{|label|
      public_send(:"#{label.gsub(/-/, '_')}_label_applies_to_user?", member)
    }
  end

  def self.determine_email_labels(message)
    labels = []
    subject_to_search = extract_header(message, 'Subject').to_s.gsub(/.*(fwd|re):\s+/i, '')
    if subject_to_search.present? && subject_to_search.length > 5
      email = Email.where(subject: subject_to_search).where('emails.created_at > ?', 14.days.ago)
        .joins(
          'inner join blasts b on b.id = blast_id and b.deleted_at is null ' +
          'inner join pushes p on p.id = push_id and p.deleted_at is null '
        )
        .order('emails.created_at desc').first
      if email
        labels.push("campaigns/#{email.blast.push.campaign.name.downcase.strip}")
      end
    end
    labels
  end

  def self.donor_label_applies_to_user?(member)
    member.donations.one_off.exists? && !middle_donor_label_applies_to_user?(member)
  end

  def self.middle_donor_label_applies_to_user?(member)
    member.donations.one_off.where('amount_in_cents >= 25000').exists?
  end

  def self.recurring_label_applies_to_user?(member)
    member.donations.recurring.exists?
  end

  def self.active_label_applies_to_user?(member)
    member.user_activity_events.actions_taken.count > 9
  end

  def self.primary_label_applies_to_user?(member)
    member.postcode && (member.postcode.electorates.map(&:name) & Electorate::TARGET_ELECTORATES).any?
  end

  def self.create_and_modify_labels_on_message(gmail, message_id, labels)
    existing_gmail_labels = gmail.list_user_labels('me').labels
    label_ids = labels.map{|label|
      existing_gmail_label = existing_gmail_labels.detect{|glabel| glabel.name == label }
      existing_gmail_label || gmail.create_user_label('me', GmailApi::Label.new(name: label))
    }.map(&:id)
    gmail.modify_message('me', message_id, GmailApi::ModifyMessageRequest.new(add_label_ids: label_ids))
  end

  def self.extract_header(message, header)
    message.payload.headers.detect{|h| h.name == header}.try(:value)
  end

  def self.already_a_job?(method)
    Delayed::Job.where("handler like ?", "%#{method}%").exists?
  end
end
