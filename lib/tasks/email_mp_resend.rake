desc 'Resend emails that were sent to the wrong Senator. This is a once off task'
task email_mp_resend: :environment do |t, args|
  pup_party = Party.where(abbreviation: 'PUP').first
  labor_party = Party.where(abbreviation: 'ALP').first

  # Find emails sent to Senator Wong (ALP) but were meant to be sent to Senator Wang (PUP)
  incorrect_emails = UserEmail.where(targets: 'senator.wong@aph.gov.au')
    .joins(:content_module)
    .includes(:content_module)
    .where("options like '%- #{pup_party.id}%' and options not like '%- #{labor_party.id}%'")

  # Update the delayed send time
  incorrect_emails.map(&:content_module).uniq.each do |email_mp_module|
    email_mp_module.delayed_end_date = 4.days.since
    email_mp_module.save!
  end

  # Resend the emails
  incorrect_emails.each do |user_email|
    user_email.targets = 'senator.wang@aph.gov.au'
    user_email.cc_me = false
    user_email.save!
    user_email.send!
  end
end
