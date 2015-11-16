class Region < ActiveRecord::Base
  has_and_belongs_to_many :postcodes
  belongs_to :jurisdiction
  has_many :senators

  extend RemoveIdProtection
  validates :name, :uniqueness => { :scope => :jurisdiction_id }

  scope :with_jurisdictions, -> { includes(:jurisdiction) }
  scope :by_jurisdiction, lambda{ |code| joins(:jurisdiction).where('code = ?', code) }
  scope :by_jurisdiction_party, lambda{ |code, parties|
	  if parties.present?
	    joins(:jurisdiction).where('code = ?', code).joins(:senators).where('party_id in (?)', parties.map(&:id.to_proc))
	  else
	    joins(:jurisdiction).where('code = ?', code)
	  end
	}

  alias_attribute :to_s, :name
end
