class Campaign < ActiveRecord::Base
  include CacheableModel

  acts_as_paranoid
  acts_as_user_stampable
  has_many :page_sequences
  has_many :pushes
  has_many :get_togethers
  belongs_to :theme
  acts_as_taggable

  include FriendlyId
  friendly_id :name, use: [:slugged, :history, :finders]

  validates :name, :length => { :maximum => 64, :minimum => 3 }
  validates_presence_of :accounts_key, on: :create
  alias_attribute :pillar, :accounts_key

  scope :find_by_pillar, -> (pillar) { where(:pillar => pillar) }

  def self.accounts_keys
    ['Core', 'Democracy', 'Economic Fairness', 'Environment', 'Human Rights', 'Organising', 'Surge', 'Grata', 'Market Impacts']
  end

  def self.valid_accounts_key?(string)
    accounts_keys.map(&:downcase).any?{|k| k == string.downcase }
  end

  def cache_key
    self.class.generate_cache_key(self.friendly_id)
  end

  def self.select_options
    self.select("id, name").all.inject([]) do |acc, campaign|
      acc << [campaign.name, campaign.id]
      acc
    end
  end

  def build_stats_query
    ask_content_modules = ['DonationModule', 'PetitionModule', 'EmailMPModule', 'EmailTargetsModule', 'CallMPModule', 'SuperModule', 'DoorknockModule', 'MerchModule', 'TargetListModule']
    campaigns            = Arel::Table.new(:campaigns, :as => 'campaigns')
    page_sequences       = Arel::Table.new(:page_sequences, :as => 'page_sequences')
    pages                = Arel::Table.new(:pages, :as => 'pages')
    content_module_links = Arel::Table.new(:content_module_links, :as => 'content_module_links')
    content_modules      = Arel::Table.new(:content_modules, :as => 'content_modules')
    user_activity_events = Arel::Table.new(:user_activity_events, :as => 'user_activity_events')

    projections = [
        content_modules[:created_at],
        page_sequences[:name].as("page_sequence_name"),
        pages[:name].as("page_name"),
        pages[:id].as("page_id"),
        content_modules[:type],
        content_modules[:id].as("content_module_id"),
        Arel::Nodes::SqlLiteral.new(%Q{COALESCE(SUM(`user_activity_events`.`activity` = 'action_taken'), 0) AS actions_taken}),
        Arel::Nodes::SqlLiteral.new(%Q{COALESCE(SUM(`user_activity_events`.`activity` = 'subscribed'), 0) AS subscriptions}),
        Arel::Nodes::SqlLiteral.new(%Q{COUNT(`user_activity_events`.`id`) AS total_actions})
    ]

      relation = campaigns.
          project(projections).
          join(page_sequences).on(page_sequences[:campaign_id].eq(campaigns[:id])).
          join(pages).on(pages[:page_sequence_id].eq(page_sequences[:id])).
          join(content_module_links).on(content_module_links[:page_id].eq(pages[:id])).
          join(content_modules).on(content_modules[:id].eq(content_module_links[:content_module_id]), content_modules[:type].in(ask_content_modules)).
          join(user_activity_events, Arel::Nodes::OuterJoin).on(user_activity_events[:page_id].eq(pages[:id]), user_activity_events[:activity].in(["action_taken", "subscribed"]))

      relation = relation.where(campaigns[:id].eq(self.id)).group(pages[:id])
      relation.order(page_sequences[:created_at].desc).to_sql
  end

  def find_or_create_offline_donation_page
    offline_donation_page_sequence = find_or_create_offline_donation_page_sequence
    offline_donation_page_sequence.find_or_create_offline_donation_page
  end

  private

  OFFLINE_DONATION_PAGE_SEQUENCE_NAME = 'Offline Donations'

  def find_or_create_offline_donation_page_sequence
    offline_page_sequence_relation = page_sequences.where(name: OFFLINE_DONATION_PAGE_SEQUENCE_NAME)
    page_sequences << PageSequence.new(name: OFFLINE_DONATION_PAGE_SEQUENCE_NAME, created_by: 'System', facebook_image: '/images/public/getup_logo.png') if offline_page_sequence_relation.count == 0
    offline_page_sequence_relation.first
  end


end
