class TrackManualEmailsSent
  EMAIL_TEMPLATE_KEYWORDS ||= [
    ["expiry", :expiring_card_email],
    ["consecutive failures", :donation_failing_email],
    ["follow-up", :donation_failing_follow_up_email],
    ["cancellation", :cancellation_warning_email]
  ]

  def import
    raise "There are already #{SentTriggerEmail.count} SentTriggerEmail records??" if SentTriggerEmail.exists?
    Donation.where(id: assigned_consecutive_failing_donation_ids).each do |donation|
      insert_to_sent_trigger_emails(donation) if donation.user
    end
  end

  private

  def insert_to_sent_trigger_emails(donation)
    puts "------------------"
    puts donation.user.email

    return if donation.user.notes == nil
    donation.user.notes.split(/\n/).each do |note|
      parse_note(note, donation) do |sent_date, template|
        insert_to_table(donation, template, sent_date)
      end
    end
  end

  def parse_note(note, donation)
    print note
    if !include_any_keyword?(note)
      puts " | SKIP donation_id: #{donation.id}"
      return
    end

    EMAIL_TEMPLATE_KEYWORDS.each do |keyword, template|
      next unless note.include?(keyword)
      next if keyword == "consecutive failures" && note.include?("follow-up")
      yield [extract_sent_date(note), template]
    end
  end

  def include_any_keyword?(note)
    EMAIL_TEMPLATE_KEYWORDS.detect{|keyword, template| note.include?(keyword) }
  end
  
  def extract_sent_date(note)
    date_regex = /(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d+,\s*\d+/i
    matched_date = date_regex.match(note)
    matched_date ? matched_date[0] : Time.now
  end

  def insert_to_table(donation, template, sent_date)
    created_email = SentTriggerEmail.create!(user: donation.user, key: template, triggered_by: donation, sent_date: sent_date)
    puts " | INSERTED #{created_email.to_s}"
  end

  def assigned_consecutive_failing_donation_ids
    query =<<SQL
      select donation_id from (
        select d.id as donation_id, substring_index(group_concat(t.successful order by t.created_at desc), ',', 2) as success_criteria
        from transactions t
        join donations d
        on t.donation_id = d.id
        and d.active = 1
        and d.assigned_to = 'Alexander Mills'
        and d.frequency != 'one_off'
        group by d.id
      ) tmp
      where success_criteria = '0,0'
SQL
    User.connection.select_values(query)
  end
end

namespace :manual_emails_sent do
  task :import => :environment do
    TrackManualEmailsSent.new.import
  end
end
