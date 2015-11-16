require "weekly_statistics_builder"

def run_stats(email_address)
  builder = WeeklyStatisticsBuilder.new
  builder.send_email(Time.now.to_date, email_address)
end

desc "Produce the configured weekly statistics send to staff"
task :weekly_statistics => :environment do
  run_stats("weekly_stats@getup.org.au")
end

desc "Produce the configured weekly statistics for testing"
task :weekly_statistics_test => :environment do
  run_stats("tech@getup.org.au")
end
