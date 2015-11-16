class DonationUpgrade < ActiveRecord::Base
  belongs_to :content_module
  belongs_to :donation
  validates :content_module, :presence => true
  validates :donation, :presence => true

  validates_numericality_of :upgrade_amount_in_cents, :only_integer => true, greater_than: 0
end
