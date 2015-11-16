class CallOutcome < ActiveRecord::Base
  DNC = "Dont Call Back"

  belongs_to :user

  validates_presence_of :user_id, :disposition, :campaign_type, :campaign_code, :campaign_name

  after_save :record_dnc
  before_validation :find_user, unless: :user_id

  def find_user
    self.user = User.find_by(email: email)
  end

  def record_dnc
    user.update_attribute(:do_not_call, true) if disposition.match(/^#{DNC}/)
  end
end
