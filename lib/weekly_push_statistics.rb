class WeeklyPushStatistics
  
  attr_reader :individual_stats,
              :group_stats

  def self.from(now, number_of_weeks)
    WeeklyPushStatistics.new(now, number_of_weeks)
  end

  def initialize(now, number_of_weeks)
    from_date = now - number_of_weeks.weeks

    Rails.logger.info { "WeeklyPushStatistics from #{from_date}" }

    sent_emails = get_sent_emails(from_date)
    emails = get_emails(sent_emails)

    email_stats = EmailStatsTable.new(emails).calculate_stats
    total_stats = combine_email_statistics(email_stats)

    @individual_stats = calculate_individual_stats(sent_emails, email_stats)
    @group_stats = calculate_group_stats(emails, total_stats, number_of_weeks)
  end

  private

  def get_sent_emails(from_date)
    created_at = SentEmail.arel_table[:created_at]
    SentEmail.includes(:email => {:blast => :push}).where(created_at.gteq(from_date)).group(:email_id).order(:created_at).reverse_order
  end

  def get_emails(sent_emails)
    sent_emails.map(&:email)
  end

  def calculate_individual_stats(sent_emails, email_stats)
    stats = {}
    sent_emails.each do |sent_email|
      email = sent_email.email
      email_stat = email_stats[email.id]
      stats[email.id] = {}
      stats[email.id][:subject] = email.subject
      stats[email.id][:blast_name] = email.blast.name
      stats[email.id][:push_name] = email.blast.push.name
      stats[email.id][:sent_date] = sent_email.created_at.strftime("%^a")
      stats[email.id][:sends] = email_stats[email.id][:email_sent][:as_value]
      stats[email.id][:views_from_sends] = check_divide_by_zero(email_stat[:email_viewed][:as_value], email_stat[:email_sent][:as_value])
      stats[email.id][:clicks_from_sends] = check_divide_by_zero(email_stat[:email_clicked][:as_value], email_stat[:email_sent][:as_value])
      stats[email.id][:clicks_from_views] = check_divide_by_zero(email_stat[:email_clicked][:as_value], email_stat[:email_viewed][:as_value])
      stats[email.id][:actions_from_clicks] = check_divide_by_zero(email_stat[:action_taken][:as_value], email_stat[:email_clicked][:as_value])
    end
    stats
  end

  def calculate_group_stats(emails, total_stats, number_of_weeks)
    stats = {}
    stats[:views_from_sends] = check_divide_by_zero(total_stats[:views], total_stats[:sends])
    stats[:clicks_from_sends] = check_divide_by_zero(total_stats[:clicks], total_stats[:sends])
    stats[:clicks_from_views] = check_divide_by_zero(total_stats[:clicks], total_stats[:views])
    stats[:actions_from_clicks] = check_divide_by_zero(total_stats[:actions], total_stats[:clicks])
    stats[:average_sends] = total_stats[:sends] / number_of_weeks.to_f
    stats[:average_emails] = emails.count / number_of_weeks.to_f
    stats
  end

  def combine_email_statistics(email_stats)
    totals = {}
    totals[:sends] = 0
    totals[:clicks] = 0
    totals[:views] = 0
    totals[:actions] = 0

    email_stats.each_value do |value|
      totals[:sends] += value[:email_sent][:as_value] || 0
      totals[:clicks] += value[:email_clicked][:as_value] || 0
      totals[:views] += value[:email_viewed][:as_value] || 0
      totals[:actions] += value[:action_taken][:as_value] || 0
    end

    totals
  end

  def check_divide_by_zero(numerator, denominator)
    if denominator != 0 then
      numerator / denominator.to_f
    else
      "#{numerator}/#{denominator}"
    end
  end
end
