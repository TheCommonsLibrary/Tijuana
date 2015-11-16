namespace :stats do
  desc 'Show the most recent financial year stats'
  task :financial_year => :environment do
    fy_stats = Stats::FinancialYearStats.new

    puts "Statistics for financial year #{fy_stats.last_financial_year[:start].year}-#{fy_stats.last_financial_year[:end].year}"

    puts "Number of new members: #{fy_stats.activities('subscribed')}"
    puts "Number of actions taken: #{fy_stats.activities('action_taken')}"
    puts "Average donation amount: #{fy_stats.average_donation_amount}"
    puts "Number of donations: #{fy_stats.number_of_donations}"
    puts "Number of donors: #{fy_stats.number_of_donors}"
    puts "Average total donation per donor: #{fy_stats.average_total_donation_per_donor}"
  end

  desc "email stats on full list emails sent between Jan to Dec for current year"
  task :full_list_email => :environment do
    time = Time.zone.now
    start_date = time.beginning_of_year
    end_date = time.end_of_year
    emails = Email.joins("inner join lists on lists.blast_id = emails.blast_id").where("lists.rules like ? and emails.created_at between ? and ?", "--- []%", start_date, end_date)
    stats = EmailStatsTable.new(emails)
    puts EmailStatsTable.columns.join(",")
    stats.rows.each do |row|
      puts row.join(",")
    end
  end
end
