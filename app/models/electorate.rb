class Electorate < ActiveRecord::Base
  has_and_belongs_to_many :postcodes
  belongs_to :jurisdiction
  has_many :mps
  has_many :candidates
  has_one :issue

  TARGET_ELECTORATES = ['Bass', 'Dickson', 'New England']

  extend RemoveIdProtection
  validates :jurisdiction, presence: true
  validates :name, :uniqueness => { :scope => :jurisdiction_id }, :unless => Proc.new { |electorate| electorate.name == 'Unincorporated' }
  validate :mp_count

  scope :with_jurisdictions, -> { includes(:jurisdiction) }
  scope :most_likely_federal, -> { joins(:jurisdiction).where("code = 'FEDERAL'").order('population desc') }
  scope :most_likely_by_jurisdiction, lambda{ |code| joins(:jurisdiction).where("code = ?", code).order('population desc') }
  scope :by_jurisdiction_party, lambda{ |code, parties|
    if parties.present?
      joins(:jurisdiction).where('code = ?', code).joins(:mps).where('party_id in (?)', parties.map(&:id.to_proc))
    else
      joins(:jurisdiction).where('code = ?', code)
    end
  }

  alias_attribute :to_s, :name

  def state
    postcodes.order('proportion desc').limit(1).first.state
  end

  private 

  def mp_count
    unless jurisdiction.nil? || jurisdiction.code == 'TAS'
      errors.add(:mps, "(#{name}) can have up to one MP.") if mps.length > 1
    end
    true
  end
end
