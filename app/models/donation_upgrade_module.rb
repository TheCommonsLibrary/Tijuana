class DonationUpgradeModule < ContentModule

  attr_reader :donation_upgrade

  def self.for_container?(layout_container)
    layout_container == :sidebar
  end

  def donation_to_upgrade
    return dummy_donation if proof_mode?
    donation
  end

  def update_action_attributes_and_validate(params)
  end

  def take_action(user, page, email=nil, params={}, options={})
    raise "Donation upgrade mismatch" unless donation && donation.id == params[:donation_id].try(:to_i)
    old_amount = donation.amount_in_dollars
    @donation_upgrade = DonationService.upgrade_recurring!(self, donation, extract_upgrade_amount_in_cents)
    success = @donation_upgrade.valid?
    if success
      UserActivityEvent.action_taken!(user, page, self, nil, email, nil)
      args = [user, old_amount, donation.frequency, donation.amount_in_dollars, donation.frequency]
      DonationUpdaterMailer.donation_update_email(*args).deliver
    end
    success
  end

  def identifies_user?
    true
  end

  def identified_user
    if secure_token_identifies_user?(params[:t], params[:secure_token])
      return TrackingTokenLookup.new(params[:t]).user
    end
  end

  def alert_tech_that_the_secure_token_failed
    ExceptionNotifier.rescue_and_mail_tech do
      raise "Unable to identify donation for #{self.inspect} with #{params.inspect}"
    end
  end

  private

  DONATION_UPGRADE_AMOUNTS = {
    'weekly' => [2, 5, 7, 10, 15, 20],
    'monthly' => [5, 10, 15, 20, 50, 100],
    'annual' => [15, 20, 50, 100]
  }

  def proof_mode?
    [params[:t], params[:secure_token]].map{|p| p.try(:include?, "NOT_AVAILABLE")}.all?
  end

  def donation
    @donation ||= begin
      return unless (user = identified_user)
      user.donations.active.recurring.unflagged.order(:created_at).last
    end
  end

  def dummy_donation
    user = User.new(email: "donationtest@example.com", first_name: "Jane", last_name: "Member")
    Donation.new(user: user, frequency: "weekly", amount_in_cents: "1000")
  end

  def extract_upgrade_amount_in_cents
    field = params[:upgrade_amount_in_dollars] == "other" ? :custom_amount_in_dollars : :upgrade_amount_in_dollars
    (params[field].to_s.gsub(/[$,]/, '').to_f * 100).round
  end

  def secure_token_identifies_user?(tracking_token, secure_token)
    SecureLinkToken.token(tracking_token) == secure_token
  end

  after_initialize do
    self.public_activity_stream_template = "{NAME|A member} donated to [a cause]." unless self.public_activity_stream_template
  end
end
