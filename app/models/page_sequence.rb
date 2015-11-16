class PageSequence < ActiveRecord::Base
  TITLE_MAX = 40
  BLURB_MAX = 160

  include CacheableModel
  acts_as_paranoid
  has_many :pages, -> { order(:position) }, dependent: :destroy
  belongs_to :campaign
  belongs_to :theme
  belongs_to :expired_redirect_page_sequence, class_name: 'PageSequence'

  scope :static, -> { where(:campaign_id => nil) }
  scope :daisy_chains, -> { where(arel_table[:name].matches("#{AppConstants.daisy_chain_prefix}%")) }
  scope :pillar_pinned, -> { where(:pillar_pin => true) }
  scope :pillar_shown, -> { where(:pillar_show => true) }
  scope :pillar_visible, -> {
    joins(:pages)
      .where('title is not null')
      .where('blurb is not null')
      .where('(pillar_pin OR pillar_show) AND !expired')
      .where('expires_at is null OR expires_at > ?', Date.today())
      .group('id')
      .order('created_at DESC')
      .limit(20)
  }
  scope :pillared, -> (pillar) { joins(:campaign).where('lower(campaigns.accounts_key) = ?', pillar) }

  include FriendlyId
  friendly_id :name, use: [:slugged, :history, :finders, :scoped], scope: :campaign

  include SerializedOptions
  option_fields :email_body, :email_subject, :tweet_text, :html_meta_description, :facebook_image

  after_initialize :defaults

  validates :email_subject, :length => { :minimum => 2, :maximum => 256 }
  validates :email_body, :length => { :minimum => 10, :maximum => 500 }
  validates :tweet_text, :length => { :minimum => 2, :maximum => TellAFriendModule::TWITTER_MAXIMUM }
  validates :name, :length => { :maximum => 218, :minimum => 3 }
  validates :facebook_image, presence: true

  validates :facebook_image, format: {
    with: /\A(https:\/\/|http:\/\/cdn.getup)/,
    message: "URL needs to be <a href=\"#{Rails.application.routes.url_helpers.admin_images_path}\">uploaded</a> or served securely (will start with 'http<b>S</b>://')"
  }, if: :pillar_page?
  validates :title, presence: true, length: { maximum: TITLE_MAX }, if: :pillar_page?
  validates :blurb, presence: true, length: { maximum: BLURB_MAX }, if: :pillar_page?

  def pillar_page?
    pillar_pin || pillar_show
  end

  def static?
    self.campaign.nil?
  end
  
  def duplicate
    new_sequence = dup
    new_sequence.pillar_pin = false
    new_sequence.pillar_show = false
    dup_number = 1
    while PageSequence.find_by_name("#{name}(#{dup_number})")
      dup_number = dup_number + 1
    end
    new_sequence.name = "#{name[0..215]}(#{dup_number})"
    new_sequence.save!
    pages.each do |original_page|
      new_page = original_page.dup
      new_page.views = 0
      new_page.page_sequence = new_sequence
      new_page.save!
      original_page.content_module_links.each do |original_link|
        new_link = original_link.dup
        new_link.page = new_page
        new_link.save!
      end
    end

    new_sequence
  end
  
  def theme_name
    theme.nil? ? self.campaign.theme.name.downcase : theme.name.downcase
  end

  def self.get_from_cache(a_campaign,sequence_friendly_id)
    key = generate_cache_key(a_campaign, sequence_friendly_id)
    sequence = Rails.cache.read(key)
    if sequence.nil?
      #FriendlyId5: rewrite this finder
      sequence = sequence_finder(a_campaign, sequence_friendly_id)
      Rails.cache.write(sequence.cache_key, sequence, :expires_in => AppConstants.default_cache_timeout) if sequence
    end
    sequence
  end

  def self.sequence_finder(campaign, sequence_slug)
    return find(sequence_slug) if sequence_slug.to_i > 0

    FriendlyId::Slug
      .where(slug: sequence_slug, sluggable_type: "PageSequence")
      .joins("JOIN page_sequences on friendly_id_slugs.sluggable_id = page_sequences.id AND page_sequences.deleted_at IS NULL")
      .where(page_sequences: {campaign_id: campaign.id})
      .first
      .sluggable
  rescue NoMethodError
    raise ActiveRecord::RecordNotFound, "Couldn't find PageSequence with slug=#{sequence_slug}"
  end

  def self.generate_cache_key(a_campaign, sequence_friendly_id)
    "campaigns/#{a_campaign.friendly_id}/pagesequences/#{sequence_friendly_id}"
  end

  def cache_key
    self.class.generate_cache_key(self.campaign, self.friendly_id)
  end

  def landing_page
    pages.first
  end

  OFFLINE_DONATION_PAGE_NAME = 'Offline Donations'

  def find_or_create_offline_donation_page
    offline_page_relation = pages.where(name: OFFLINE_DONATION_PAGE_NAME)
    pages << create_offline_donation_page if offline_page_relation.count == 0
    offline_page_relation.first
  end

  def create_offline_donation_page
    page = Page.new(name: OFFLINE_DONATION_PAGE_NAME, created_by: 'System')
    donation_module = DonationModule.new(title: 'Offline Donations', thermometer_threshold: 99999999)
    page.content_modules << donation_module
    page
  end

  def self.find_global_donations_page_sequence
    self.static.find_by_name('Donate')
  end

  def reached_expiry?
    return self.expired unless !self.expired
    self.expires_at.nil? ? false : self.expires_at.to_date <= Date.today
  end

  private
  
  def defaults
    self.email_subject ||= "Check out this GetUp! campaign"
    self.email_body ||= "Why don't you check out this?"
    self.tweet_text ||= "Why don't you check out this?"
    self.html_meta_description ||= AppConstants.default_page_description
  end
end
