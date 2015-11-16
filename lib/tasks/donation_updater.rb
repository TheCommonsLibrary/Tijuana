class DonationUpdater
  def initialize(csv_input)
    @index = 1
    @failed_records = []
    @csv_input = csv_input
  end

  def update_donations
    CSV.foreach(@csv_input, :headers => true) do |row|
      begin
        update_donation_and_email_donor(row, @index)
      rescue => e
        @failed_records << {reason: e.message, row_no: @index+1, row: row}
      end
      @index = @index + 1
    end

    print_failed_records
  end

private

  def print_failed_records
    if @failed_records.size > 0
      log "############### Failed Records"
      @failed_records.each do |failure|
        log failure.inspect
      end
    end
  end

  def update_donation_and_email_donor(row, index)
    donation_id = row['d.id']
    raise "Invalid donation ID: #{donation_id}" if donation_id.blank?

    donation = Donation.find(donation_id)
    verify_donation(donation, row)
    validate_row(row)

    donation.frequency = row['new frequency']
    donation.amount_in_cents = row['new amount'].to_f * 100
    donation.save!
    email_donor(row, donation.user)
    log "Row: #{index+1} - Updated Donation: #{donation.id}"
  end

  def email_donor(row, user)
    DonationUpdaterMailer.donation_update_email(user, row['old amount'], row['old frequency'], row['new amount'], row['new frequency']).deliver
  end

  def validate_row(row)
    raise "New amount invalid: #{row['new amount']}" if row['new amount'].to_i <= 0
    raise "New frequency invalid: #{row['new frequency']}" if !['weekly', 'monthly', 'annual'].include?(row['new frequency'].downcase)
  end

  def verify_donation(donation, row)
    raise "Donation email does not match. donation email: #{donation.user.email}" if donation.user.email != row['u.email']
    raise "Donation is not a credit card donation. Payment method: #{donation.payment_method}" if donation.payment_method != 'credit_card'
    raise "User ID does not match. User ID: #{donation.user.id}" if donation.user.id != row['u.id'].to_i
    raise "Donation amount does not match. donation amount: #{donation.amount_in_cents}" if donation.amount_in_cents != row['old amount'].to_i * 100
    raise "Donation frequency does not match. donation frequency: #{donation.frequency}" if donation.frequency != row['old frequency']
    raise "Donation ID does not match. donation ID: #{donation.id}" if donation.id != row['d.id'].to_i
  end

  def log(message)
    puts(message) unless Rails.env.test?
  end
end
