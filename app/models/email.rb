require 'string_without_smartquotes'

class Email < ActiveRecord::Base
  include EmailFormatHelper
  acts_as_paranoid
  belongs_to :blast

  validates :blast, :presence => true
  validates :name, :presence => true
  validates :from_name, :presence => true
  validates :from_address, :email_format => {:message => 'is not valid'}
  validates :reply_to_address, :email_format => {:message => 'is not valid'}
  validates :subject, :presence => true
  validates :body, :presence => true, :no_naked_links => true, :links => true
  validate :get_together_exists?, :if => -> { get_together_id.present? }
  validate :merge_tokens_valid?

  before_validation :remove_smart_quotes

  after_initialize :defaults

  before_save :clear_test_timestamp, if: :email_field_changed?

  scope :proofed_emails, -> { where("test_sent_at IS NOT ?", nil) }

  DEFAULT_TEST_EMAIL_RECIPIENT = 'test@getup.org.au'
  URL_REGEX_HTML = /["|']https?\:\/\/[^"|']+/m
  URL_REGEX_PLAIN_TEXT = /https?\:\/\/([a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/+\S+)?)/m

  def email_field_changed?
    (self.changed & [ 'from_address', 'reply_to_address', 'subject', 'body', 'get_together_id' ]).any?
  end
  private :email_field_changed?

  def valid_merge_tokens?(src, text)
    valid = true
    text.scan(SendgridTokenReplacement::TOKENS_REGEX).uniq.each do |token_pair|
      token = token_pair[0].split("|").try(:first)
      if token =~ /^MERGE/ && !MergeToken.valid_token?(token)
        errors.add(src, "Invalid merge token: #{MergeToken.get_eval(token)}")
        valid = false
      end
    end
    valid
  end

  def merge_tokens_valid?
    valid = valid_merge_tokens?(:body, self.body)
    valid ||= valid_merge_tokens?(:subject, self.subject)
    valid
  end

  def get_together_exists?
    unless GetTogether.where(id: get_together_id).count > 0
      errors.add(:get_together_id, "with ID #{get_together_id} not found.")
    end
  end

  def send_test!(recipients=[])
    recipients << DEFAULT_TEST_EMAIL_RECIPIENT
    begin
      Emailer.blast(self, :recipients => recipients, :test => true).deliver
      Email.update_all({:test_sent_at => Time.now}, {:id => self.id}) # update without callbacks
    rescue =>  e
      TechMailer.user_warning(recipients, "PROOFING ERROR", "Something went wrong sending proof, see tech team. \nTech info: " + e.message).deliver
      ExceptionNotifier.notify_exception(e)
    end
  end
  handle_asynchronously(:send_test!) unless Rails.env.test?

  def html_body
    TokenScanner.new(self.body, secure_links).add_tracking_hash_to_links(URL_REGEX_HTML, SendgridTokenReplacement::TOKENS_REGEX)
  end

  def plain_text_body
    TokenScanner.new(Nokogiri::HTML::DocumentFragment.parse(self.body).text, secure_links).add_tracking_hash_to_links(URL_REGEX_PLAIN_TEXT, SendgridTokenReplacement::TOKENS_REGEX)
  end

  def deliver_blast_in_batches(user_ids, batch_size=1000)
    log("Starting deliver_blast_in_batches")
    user_ids.each_slice(batch_size) do |slice|
      begin
        deliver_slice(slice)
      rescue Exception => e
        PushLog.log_exception(self, slice, e)
        log("Had EXCEPTION: #{e}")
        ExceptionNotifier.notify_exception(e)
      end
    end
  end

  def deliver_slice(slice)
    log("Taken slice of #{slice.count} user ids")
    recipients = User.select(:email).where(:id=>slice).order(:email).map(&:email)
    log("Loaded users for slice")
    Emailer.blast(self, :recipients => recipients).deliver
    log("Delivered emails for slice")
    self.blast.push.batch_create_sent_activity_event!(slice, self)
    log("Created sent activity events for slice")
  end

  def clear_test_timestamp
    self.test_sent_at = nil
  end

  def proofed?
    self.test_sent_at.present?
  end

  def subject_line_test?
    name.include?(subject_line_prefix)
  end

  def create_subject_line_tests!(subjects)
    return if subject_line_test? || subjects.empty? || !proofed?
    base_name = name.split(' - ').first
    update_attribute(:test_sent_at, test_sent_at)
    subjects.each do |subject|
      subject_test_email = dup
      subject_test_email.name = "#{subject_line_prefix} #{base_name} - #{subject} "
      subject_test_email.subject = subject
      subject_test_email.save!
      subject_test_email.update_attribute(:test_sent_at, test_sent_at)
    end
  end

  def has_been_sent?
    SentEmail.where(email_id: self.id).count > 0
  end

  private

  def subject_line_prefix
    '[SUBJECT LINE TEST]'
  end

  def remove_smart_quotes
    self.subject = subject.without_smartquotes if subject.present?
    self.body = body.without_smartquotes if body.present?
  end

  def defaults
    self.from_name ||= "GetUp!"
    self.from_address ||= "info@getup.org.au"
    self.reply_to_address ||= "contact@getup.org.au"
  end

  def log(msg)
    Rails.logger.info("BLAST_DEBUG Email##{self.id}: " + msg)
  end
end
