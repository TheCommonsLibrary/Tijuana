class DonorUpgrader
  def initialize(csv_input)
    @index = 1
    @failed_records = []
    @csv_input = Rails.root.join(csv_input)
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
    donations = find_donation(row['u.email'], row['old amount'].to_f * 100, row['oldfrequency'])

    raise "Cannot find donation for #{row['u.email']} with amount: $#{row['old amount']} frequency: #{row['oldfrequency']}" if donations.blank?
    raise "More than one donation for #{row['u.email']} with amount: $#{row['old amount']} frequency: #{row['oldfrequency']} #{donations.map{|d| d.id}.join(",")}" if donations.size > 1

    donation = Donation.find(donations.first.id)
    verify_donation(donation, row)
    validate_row(row)

    donation.frequency = row['newfrequency']
    donation.amount_in_cents = row['new amount'].to_f * 100
    donation.save!
    email_donor(row, donation.user)
    log "Row: #{index+1} - Updated Donation: #{donation.id}"
  end

  def email_donor(row, user)
    DonationUpdaterMailer.donation_update_email(user, row['old amount'], row['oldfrequency'], row['new amount'], row['newfrequency']).deliver
  end

  def validate_row(row)
    raise "New amount invalid: #{row['new amount']}" if row['new amount'].to_i <= 0
    raise "New frequency invalid: #{row['newfrequency']}" if !['weekly', 'monthly', 'annual'].include?(row['newfrequency'].downcase)
  end

  def verify_donation(donation, row)
    raise "Donation email does not match. donation email: #{donation.user.email}" if donation.user.email != row['u.email']
    raise "Donation is not a credit card donation. Payment method: #{donation.payment_method}" if donation.payment_method != 'credit_card'
    raise "Donation amount does not match. donation amount: #{donation.amount_in_cents}" if donation.amount_in_cents != (row['old amount'].to_f * 100).to_i
    raise "Donation frequency does not match. donation frequency: #{donation.frequency}" if donation.frequency != row['oldfrequency']
  end

  def log(message)
    puts(message) unless Rails.env.test?
  end

  def find_donation(user_email, amount_in_cents, frequency)
    Donation.where(user_id: User.where(email: user_email).first.id, amount_in_cents: amount_in_cents, frequency: frequency, active: true)
  end
end

