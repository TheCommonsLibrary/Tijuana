class WeeklyDonationStatistics
  attr_reader :periodic_donations_amount_in_dollars,
              :one_off_donations_amount_in_dollars,
              :donations_by_page_sequence,
              :one_off_donations_count,
              :new_recurring_donor_count,
              :ordered_donation_hash_keys

  def self.from(now, number_of_weeks)
    WeeklyDonationStatistics.new(now, number_of_weeks)
  end

  def initialize(now, number_of_weeks)
    date_from = now - number_of_weeks.weeks
    donations_by_page_sequence_sql = donation_statistics_by_campaign_query(date_from)
    @donations_by_page_sequence = build_donation_statistic_hash_from_db_query(donations_by_page_sequence_sql)
    @ordered_donation_hash_keys = sort_by_page_sequence_total_desc(@donations_by_page_sequence)
    set_donation_amounts(number_of_weeks)
    one_off_donations_count_sql = count_of_one_of_donations_query(date_from)
    @one_off_donations_count = calculate_weekly_average(get_count_from_db_query(one_off_donations_count_sql), number_of_weeks)
    new_recurring_donor_count_sql = recurring_donors_query(date_from)
    @new_recurring_donor_count = calculate_weekly_average(get_count_from_db_query(new_recurring_donor_count_sql), number_of_weeks)
    log_statistic("Hash", @donations_by_page_sequence)
    log_statistic("One Off Count", @one_off_donations_count)
    log_statistic("New Recurring Donor", @new_recurring_donor_count)
  end

  private

  def sort_by_page_sequence_total_desc(hash)
    hash.keys.sort {|a, b| get_total_of_totals(hash[b]) <=> get_total_of_totals(hash[a])}
  end

  def get_total_of_totals(page_sequence)
    periodic = page_sequence[:totals][:periodic] || 0
    one_off = page_sequence[:totals][:one_off] || 0
    periodic + one_off
  end

  def set_donation_amounts(number_of_weeks)
    @periodic_donations_amount_in_dollars = calculate_weekly_average(get_total_donation_amount(:periodic), number_of_weeks)
    @one_off_donations_amount_in_dollars = calculate_weekly_average(get_total_donation_amount(:one_off), number_of_weeks)
  end

  def donation_statistics_by_campaign_query(date_from)
    %Q{
      SELECT c.name as campaign_name, ps.id as page_sequence_id, ps.name as page_sequence_name, p.name as page_name, d.frequency, SUM(t.amount_in_cents) / 100 as total
      FROM transactions t
      JOIN donations d ON d.id = t.donation_id
      JOIN pages p on p.id = d.page_id
      JOIN page_sequences ps on ps.id = p.page_sequence_id
      LEFT JOIN campaigns c ON c.id = ps.campaign_id
      WHERE t.created_at > '#{date_from}'
      AND t.successful = true
      GROUP BY campaign_name, page_sequence_name, page_name, frequency
    }
  end

  def count_of_one_of_donations_query(date_from)
    %Q{
      SELECT count(*) AS count
      FROM donations d
      JOIN transactions t ON t.donation_id = d.id
      WHERE d.created_at >= '#{date_from}'
      AND d.frequency = 'one_off'
      AND t.successful = true
      AND t.refunded = false
      AND t.amount_in_cents > 0
      AND d.flagged_since IS NULL
    }
  end

  def recurring_donors_query(date_from)
    %Q{
      SELECT COUNT( DISTINCT d.user_id) AS count
      FROM donations d
      JOIN transactions t ON t.donation_id = d.id
      WHERE d.created_at >= '#{date_from}'
      AND d.frequency != 'one_off'
      AND t.successful = true
      AND t.refunded = false
      AND t.amount_in_cents > 0
      AND d.flagged_since IS NULL
    }
  end

  def build_donation_statistic_hash_from_db_query(sql)
    ActiveRecord::Base.connection.exec_query(sql).to_a.inject({}) do |hash, row|
      hash[row['page_sequence_id']] = {:campaign => row['campaign_name'], :name => row['page_sequence_name'], :pages => {}, :totals => {}} if hash[row['page_sequence_id']].nil?
      totals = hash[row['page_sequence_id']][:totals]
      pages = hash[row['page_sequence_id']][:pages]
      pages[row['page_name']] = {} if pages[row['page_name']].nil?
      page_names = pages[row['page_name']]
      set_totals(page_names, row, totals)
      hash
    end
  end

  def get_count_from_db_query(sql)
    ActiveRecord::Base.connection.exec_query(sql)
    .to_a
    .inject(0) { |count, el| count += el['count']; count }
  end

  def calculate_weekly_average(value, number_of_weeks)
    value / number_of_weeks.to_f
  end

  def get_total_donation_amount(frequency)
    @donations_by_page_sequence
      .map{ |k,v| v.map { |k,v| v[frequency] unless k == :campaign || k == :name} }
      .flatten
      .inject(0){|count, amount| count += amount unless amount.nil?; count}
  end

  def set_totals(page_names, row, totals)
    unless row['frequency'] == 'one_off'
      set_periodic(page_names, row, totals)
    else
      set_one_off(page_names, row, totals)
    end
  end

  def set_periodic(page_names, row, totals)
    page_names[:periodic] = 0 if page_names[:periodic].nil?
    totals[:periodic] = 0 if totals[:periodic].nil?
    page_names[:periodic] += row['total']
    totals[:periodic] += row['total']
  end

  def set_one_off(page_names, row, totals)
    page_names[:one_off] = row['total']
    totals[:one_off] = 0 if totals[:one_off].nil?
    totals[:one_off] += row['total']
  end

  def log_statistic(title, statistic)
    Rails.logger.info { "WeeklyDonationStatistics #{title}: #{statistic}" }
  end

end
