class EmailStatsTable
  include ReportTable

  def self.columns
    ["Created", "Blast", "Email", "Sent to", "Opens", "Opens % (opens / sent)", "Clicks", "Clicks % (clicks / opens)", "Actions Taken", "Actions Taken % (actions / sent)", "New Members", "Unsubscribed", "Unsubscribed % (unsubscribes / opens)", "Donations", "Total $", "Avg. $", 'Median $']
  end

  def initialize(emails)
    @emails = emails
  end

  def rows
    pre_calculate_totals
    stats = calculate_stats
    @emails.inject([]) { |rows, email| rows << row_for(email, stats[email.id]); rows }
  end

  def calculate_stats
    activities = ['email_sent', 'email_viewed', 'email_clicked', 'action_taken', 'subscribed', 'unsubscribed']
    stats = init_stats_hash(activities)
    all_statistics = []
    @emails.each do |email|
      ['email_sent', 'email_viewed', 'email_clicked'].each do |activity|
        all_statistics << calculate_email_activity(email, activity)
      end

      ['action_taken', 'subscribed', 'unsubscribed'].each do |activity|
        all_statistics << calculate_other_activities(email.id, activity)
      end
    end

    all_statistics.each do |metric|
      totals = {
        :sent => 0,
        :opens => 0,
        :clicks => 0
      }

      { :email_sent => :sent,
        :email_viewed => :opens,
        :email_clicked => :clicks,
      }.each do |comparison_metric, total_value|
        raw_total = all_statistics.select { |s| s[0] == metric[0] && s[1].to_sym == comparison_metric }
        totals[total_value] = raw_total.empty? ? 0 : raw_total[0][2]
      end

      case metric[1].to_sym
      when :email_viewed
        confidence_interval = calculate_confidence_interval(metric, totals[:sent])
      when :action_taken
        confidence_interval = calculate_confidence_interval(metric, totals[:sent])
      else
        confidence_interval = calculate_confidence_interval(metric, totals[:opens])
      end

      stats[metric[0]][metric[1].to_sym][:as_value] = metric[2]
      stats[metric[0]][metric[1].to_sym][:as_percentage] = "#{confidence_interval}"
    end

    stats
  end

  private

  def init_stats_hash(activities)
    stats = {}
    @emails.each do |email|
      stats[email.id] = {}
      activities.each do |activity|
        stats[email.id][activity.to_sym] = {:as_value => 0, :as_percentage => "0%"}
      end
    end
    stats
  end

  def pre_calculate_totals
    @email_totals = @emails.inject({}) do |acc, email|
      acc[email.id] = {:txn_count => 0, median: 0, :amount_in_cents => 0}
      acc
    end
    totals = Donation.select('donations.email_id, COUNT(transactions.id) as txn_count, COALESCE(SUM(transactions.amount_in_cents), 0) as amount_in_cents').
        joins(:transactions).
        where(:transactions => {:successful => true}, :donations => {:email_id => @emails.map(&:id)}).
        group('donations.email_id')
    totals.each do |total|
      if total.txn_count > 0
        @email_totals[total.email_id][:median] = Donation.joins(:transactions)
          .where(:transactions => {:successful => true}, :donations => {:email_id => total.email_id})
          .order('donations.amount_in_cents')
          .offset(total.txn_count / 2)
          .limit(1).first.try(:amount_in_cents) || 0
      end
      @email_totals[total.email_id][:txn_count] = total.txn_count
      @email_totals[total.email_id][:amount_in_cents] = total.amount_in_cents
    end
  end

  def total_and_average_donations_columns(email)
    dollars_raised = @email_totals[email.id][:amount_in_cents] / 100
    [
      @email_totals[email.id][:txn_count],
      number_to_currency(dollars_raised),
      @email_totals[email.id][:txn_count] > 0 ? number_to_currency(dollars_raised / @email_totals[email.id][:txn_count]) : number_to_currency(0.00),
      number_to_currency(@email_totals[email.id][:median] / 100)
    ]
  end

  def calculate_email_activity(email, activity)
    query = <<SQL
select count(distinct user_id) as count
from push_#{email.blast.push.id}
where email_id=#{email.id} and activity='#{activity}'
SQL
    [email.id, activity, ActiveRecord::Base.connection.execute(query).to_a.first.first]
  end

  def calculate_other_activities(email_id, activity)
    query = <<SQL
select count(distinct user_id) as count
from user_activity_events
where email_id=#{email_id} and activity='#{activity}'
SQL
    [email_id, activity, ActiveRecord::Base.connection.execute(query).to_a.first.first]
  end

  def calculate_confidence_interval(metric, total)
    percentage = 0
    ratio = metric[2].to_f / total.to_f
    percentage = ratio*100 unless total == 0
    if percentage == 0
      confidence_interval = "0%"
    elsif percentage == 100
      confidence_interval = "100%"
    else
      pv = ratio*(1-ratio).to_f
      if pv >= 0
        sd_pc = Math.sqrt((pv)/total.to_f)*100
        plus_or_minus = sd_pc*1.96
        minimum = (percentage - plus_or_minus).round < 0 ? 0 : (percentage - plus_or_minus).round
        maximum = (percentage + plus_or_minus).round > 100 ? 100 : (percentage + plus_or_minus).round
        confidence_interval = "#{minimum}% - #{maximum}%"
      else
        confidence_interval = "N/A"
      end
    end
    confidence_interval
  end

  def row_for(email, stats)
    row = [
        email.created_at.to_date.to_s,
        email.blast.name,
        email.name,
        stats[:email_sent][:as_value],
        stats[:email_viewed][:as_value],
        stats[:email_viewed][:as_percentage],
        stats[:email_clicked][:as_value],
        stats[:email_clicked][:as_percentage],
        stats[:action_taken][:as_value],
        stats[:action_taken][:as_percentage],
        stats[:subscribed][:as_value],
        stats[:unsubscribed][:as_value],
        stats[:unsubscribed][:as_percentage]
    ]
    row += total_and_average_donations_columns(email)
    row
  end
end
