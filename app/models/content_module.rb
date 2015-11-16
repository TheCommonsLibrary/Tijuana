class ContentModule < ActiveRecord::Base
  include InlineTokenReplacement
  include AnalyticsHelper

  has_many :content_module_links
  has_many :pages, :through => :content_module_links
  has_many :users, :through => :user_activity_events
  has_many :user_activity_events
  has_one :get_together

  validates :title, :length => {:maximum => 128, :minimum => 3}, :if => :is_ask?
  # as public_stream_html, which is built based on public_activity_stream_template, is stored as varchar(255),
  # public_activity_stream_template's length should only have maximum 150 characters just in case there is a very long user's first name
  validates :public_activity_stream_template, :length => {:maximum => 150, :minimum => 3}, :if => :is_ask?
  attr_reader :user_notifier
  attr_reader :email_notifier
  attr_accessor :session
  attr_accessor :cookies
  attr_accessor :flash
  attr_accessor :params
  attr_accessor :current_user

  before_validation :remove_smart_quotes

  include SerializedOptions

  option_fields :custom_fields

  def identifies_user?
    false
  end

  def identified_user
  end

  def donatable?
    false
  end

  def actions_on_page
  end

  def member_value_money_module?
    false
  end

  def member_value_time_module?
    false
  end

  def member_value_voice_module?
    false
  end

  def show_steps?
    return false
  end

  def pre_action_data_for_logger(options={})
    return {}
  end

  def post_action_data_for_logger
    return { module_type: self.class.name }
  end

  def post_action_user_activity_event
    @uae
  end

  def create_action(action, options={})
    shared_connection = options[:shared_connection]
    acquisition_source = options[:acquisition_source]
    if action.save
      @uae = ContentModule.create_uae_and_shared_connection(action, action, shared_connection, acquisition_source)
      track_analytics_event(self.class.name.titlecase.downcase, 'action taken', nil, 1)
      return action
    end
    false
  end

  def self.create_uae_and_shared_connection(action, user_response, shared_connection, acquisition_source)
    event_source = nil
    if action.respond_to? :source
      event_source = action.source
    end
    uae = UserActivityEvent.action_taken!(action.user, action.page, action.content_module, user_response, action.email, event_source, acquisition_source)

    ExceptionNotifier.rescue_and_mail_tech do
      if shared_connection
        shared_connection.user_activity_event = uae
        shared_connection.save! if shared_connection.valid?
      end
    end
    uae
  end

  def handles_address?
    false
  end

  def handles_extended_validation?
    false
  end

  def self.for_container?(layout_container)
    true
  end

  def is_ask?
    self.respond_to?(:take_action)
  end

  def user_notifier=(notifier_proc)
    @user_notifier = notifier_proc
  end

  def notify_user(level, title, message)
    raise "No user notifier set on Content Module" unless @user_notifier
    @user_notifier.call(level, title, message)
  end

  def email_notifier=(email_notifier_proc)
    @email_notifier = email_notifier_proc
  end

  def notify_email(exception, options)
    raise "No email notifier set on Content Module" unless @email_notifier
    @email_notifier.call(exception, options)
  end

  def bookmarked?
    @is_bookmarked ||= BookmarkedContentModule.where(:content_module_id => self.id).count > 0
  end

  def linked?
    @is_linked ||= ContentModuleLink.where(:content_module_id => self.id).count > 1
  end

  def public_activity_stream_html(user, page)
    html = replace_tokens(public_activity_stream_template,
                          "NAME" => lambda { |default| "<span class=\"name\">#{user.greeting || default}</span>" }
    )
    campaign_id = page.page_sequence.campaign ? page.page_sequence.campaign.id : nil
    path = Rails.application.routes.url_helpers.page_path(campaign_id, page.page_sequence.id, page.page_sequence.pages.first.id)
    html.gsub(/\[(.*)\]/, "<a href=\"#{path}\">\\1</a>")
  end

  def first_image
    needle = Nokogiri::HTML::DocumentFragment.parse(self.content).css("img")
    if needle && needle.size > 0
      needle.first["src"]
    else
      false
    end
  end

  def set_user_and_page(user, page)
  end

  def if_trackable_donation_made
  end

  private

  def remove_smart_quotes
    self.content = content.without_smartquotes if content.present?
  end

end

# Required to make reloading STI in development work
# https://github.com/rails/rails/issues/8699
unless Rails.configuration.cache_classes
  Dir["#{Rails.root}/app/models/*module.rb"].each do |file|
    require_dependency file
  end
end
