class Senator < ActiveRecord::Base
  belongs_to :party
  belongs_to :region

  extend RemoveIdProtection

  before_validation :clean_email

  validates :email, :presence => true, :email_format => {:message => 'is invalid'}

  scope :by_jurisdiction, -> {
    includes(:party, :region => [:jurisdiction])
      .order('regions.jurisdiction_id, regions.name')
  }

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def clean_email
    self.email.strip!
  end
end
