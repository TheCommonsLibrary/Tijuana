class Party < ActiveRecord::Base
  has_many :mps
  belongs_to :jurisdiction

  extend RemoveIdProtection

  validates :abbreviation, :uniqueness => { :scope => :jurisdiction_id }

  scope :with_jurisdictions, -> { includes(:jurisdiction) }
  scope :find_all_by_abbreviation, lambda{ |abbreviations| where('abbreviation in (?)', abbreviations) }

  def self.select_options
    Party.all.map { |p| [p.name, p.id] }
  end

  alias_attribute :to_s, :name
end
