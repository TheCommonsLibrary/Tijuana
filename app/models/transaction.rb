class Transaction < ActiveRecord::Base
  class RefundFailedError < StandardError; end
  
  self.per_page = 15

  belongs_to :donation
  belongs_to :refund_of, :class_name => "Transaction"
  has_one :refunded_by, :class_name => "Transaction", :foreign_key => "refund_of_id"  
  
  scope :successful, -> { where(:successful => true, :refunded => false, :refund_of_id => nil) }

  validates :created_at, :presence => { :message => "date can't be blank"}, :if => :offline_donation?

  def refund!(amount_in_cents_to_refund)
    if donation.payment_method.to_sym == :credit_card
      DonationService.new.refund(amount_in_cents_to_refund, self)
    else
      raise RefundFailedError.new("Don't know how to refund transactions with payment method '#{donation.payment_method}'.")
    end
  end
  
  def refund?
    !refund_of.nil?
  end

  def less_than_one_month
    created_at > 1.months.ago
  end
  
  def amount_in_dollars
    self.class.convert_to_dollars(self.amount_in_cents)
  end

  def self.convert_to_dollars(cents)
    cents.to_f / 100
  end

  def self.convert_to_cents(dollars)
    dollars.to_f * 100
  end

  def self.filter_by(options={})
    options = cleanup(options)
    projections = unless options[:group_by].blank?
      projections_for_group_by(options[:group_by])
    else
      default_projections
    end

    transactions = Transaction.select(projections).
        joins(:donation => :user).
        joins("LEFT OUTER JOIN pages ON pages.id = donations.page_id").
        joins("LEFT OUTER JOIN page_sequences ON page_sequences.id = pages.page_sequence_id").
        joins("LEFT OUTER JOIN campaigns ON campaigns.id = page_sequences.campaign_id")

    from_date = options[:from_date].blank? ? nil : Date.strptime(options[:from_date], '%d-%m-%Y')
    to_date = options[:to_date].blank? ? nil : Date.strptime(options[:to_date], '%d-%m-%Y')
    transactions = transactions.where('transactions.created_at >= (?)', filter_from_date(options))  unless filter_from_date(options).nil?
    transactions = transactions.where('transactions.created_at < (?)', filter_to_date(options))  unless filter_to_date(options).nil?
    transactions = transactions.where(:transactions => {:id => options[:id]}) unless options[:id].blank?
    transactions = transactions.where(:users => {:id => options[:user_id]}) unless options[:user_id].blank?
    transactions = transactions.where('transactions.amount_in_cents >= (?)', convert_to_cents(options[:minimum_dollars])) unless options[:minimum_dollars].blank?
    transactions = transactions.where('transactions.amount_in_cents <= (?)', convert_to_cents(options[:maximum_dollars])) unless options[:maximum_dollars].blank?
    transactions = transactions.where(donations: {payment_method: options[:payment_methods]}) unless options[:payment_methods].blank?
    transactions = transactions.where(successful: options[:status] == "successful" ? true : false) unless options[:status].blank?
    if !options[:user_email].blank?
      transactions.joins("LEFT OUTER JOIN users ON users.id = donations.user_id")
      transactions = transactions.where(users: {email: options[:user_email]})
    end

    transactions = append_group_by(transactions, options[:group_by]) unless options[:group_by].blank?
    transactions.order('transactions.created_at DESC')
  end

  private

  def self.filter_from_date(options)
    if !options[:from_date].blank?
      Time.zone.local_to_utc(Date.strptime("#{options[:from_date]}", '%d-%m-%Y').to_time)
    else
      nil
    end
  end

  def self.filter_to_date(options)
    if !options[:to_date].blank?
      Time.zone.local_to_utc(Date.strptime("#{options[:to_date]}", '%d-%m-%Y').to_time + 1.day)
    else
      nil
    end
  end

  def self.cleanup(options)
    options ||= {}
    options[:payment_methods].reject! { |e| e.blank? } unless options[:payment_methods].blank?
    options[:group_by].reject! { |e| e.blank? } unless options[:group_by].blank?
    options
  end

  def self.projections_for_group_by(group_by_options)
    projections = group_by_options.inject([]) do |acc, option|
      case option.to_sym
        when :year_month
          acc << "YEAR(transactions.created_at) as 'year'" << "MONTH(transactions.created_at) as 'month'"
        when :campaign
          acc << "campaigns.name AS 'campaign_name'"
        when :frequency
          acc << "donations.frequency"
      end
      acc
    end
    projections << "SUM(transactions.amount_in_cents) as 'total'"
    projections.join(",")
  end

  def self.default_projections
    <<PROJECTIONS
  transactions.id AS 'txn_id',
  transactions.amount_in_cents,
  transactions.successful,
  transactions.created_at,
  transactions.settled_on,
  transactions.bank_ref,
  transactions.txn_ref,
  transactions.ip_address,
  transactions.gateway_name,
  transactions.recurring_flag,
  donations.id AS 'donation_id',
  donations.cheque_number,
  donations.cheque_name,
  donations.cheque_bank,
  donations.cheque_branch,
  donations.cheque_bsb,
  donations.cheque_account_number,
  donations.frequency,
  donations.payment_method,
  donations.card_type,
  donations.name_on_card,
  users.id AS 'user_id',
  users.email,
  campaigns.name AS 'campaign_name',
  page_sequences.name AS 'page_sequence_name',
  pages.name AS 'page_name'
PROJECTIONS
  end

  def self.append_group_by(transactions, group_by_options)
    expressions = group_by_options.inject([]) do |acc, option|
      case option.to_sym
        when :year_month
          acc << "YEAR(transactions.created_at)" << "MONTH(transactions.created_at)"
        when :campaign
          acc << "campaigns.name"
        when :frequency
          acc << "donations.frequency"
      end
      acc
    end
    transactions.group(expressions.join(","))
  end

  def offline_donation?
    (self.message =~ /^Offline donation/) ? true : false
  end
end
