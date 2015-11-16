require "weekly_push_statistics"
require "weekly_user_statistics"
require "weekly_statistics"
require "weekly_donation_statistics"

class WeeklyStatisticsBuilder
  def send_email(time, *to_email_addresses)
    to = to_email_addresses.join(',')

    subject = "#{time} - Weekly Statistics"

    push_stats = WeeklyStatistics.new(
      "push_statistics",
      WeeklyPushStatistics.from(time, 1),
      WeeklyPushStatistics.from(time, 26)
    )

    user_stats = WeeklyStatistics.new(
      "user_statistics",
      WeeklyUserStatistics.from(time, 1),
      WeeklyUserStatistics.from(time, 26)
    )

    donation_stats = WeeklyStatistics.new(
      "donation_statistics",
      WeeklyDonationStatistics.from(time, 1),
      WeeklyDonationStatistics.from(time, 26)
    )

    weekly_stats = {
      :push => push_stats,
      :user => user_stats,
      :donation => donation_stats
    }

    TechMailer.weekly_statistics_email(
      to,
      subject,
      weekly_stats,
    ).deliver
  end
end