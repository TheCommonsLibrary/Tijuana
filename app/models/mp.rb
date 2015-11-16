class Mp < ActiveRecord::Base
  belongs_to :party
  belongs_to :electorate

  before_validation :clean_email

  validates :electorate, presence: true
  validates :last_name, :presence => true
  validates :first_name, :presence => true
  validates :email, :presence => true, :email_format => {:message => 'is invalid'}
  validates :parliament_phone, presence: true, if: :federal?
  validates :office_state, :presence => true
  validates :office_phone, :presence => true
  validates :office_postcode, :presence => true
  validate :mps_per_electorate

  scope :by_jurisdiction, -> {
    includes(:party, :electorate => [:jurisdiction])
      .order('electorates.jurisdiction_id, electorates.name')
  }

  extend RemoveIdProtection

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def federal?
    electorate.jurisdiction.federal?
  end

  def clean_email
    self.email.strip!
  end

  def too_many_mps?
    mps = electorate.mps
    mps.size > 0 && !mps.include?(self)
  end

  def mps_per_electorate
    unless electorate.nil? || electorate.jurisdiction.code == 'TAS'
      errors.add(:electorate, "(#{electorate.name}) has too many MPs") if too_many_mps?
    end
    true
  end
end
