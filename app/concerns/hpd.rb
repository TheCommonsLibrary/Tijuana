module Hpd
  extend ActiveSupport::Concern

  def hpd(min, max, ratio)
    return unless hpd = calculate_hpd(min, max)
    (hpd * ratio).round
  end

  def hpd_amounts(email_id, link)
    if hpd = calculate_hpd(DonationModule::HPDA_FLOOR, DonationModule::HPDA_CAP)
      amounts = DonationModule::RELATIVE_TO_HPD_AMOUNTS
        .split(', ')
        .select{|r| r.include?('*') }
        .map{|r| r.gsub('*', '').to_i }
        .map{|ratio| (hpd * (ratio.to_f / 100)).round }
        .reverse
    else
      amounts = DonationModule::DEFAULT_SUGGESTED_AMOUNTS
        .split(', ')
        .select{|a| a.include?('*') }
        .map{|a| a.gsub('*', '').to_i }
        .reverse
    end
    link_with_token = link + (link.include?('?') ? '&' : '?') + "t=#{EmailTrackingToken.encode(id, email_id)}"
    html = '<div style="overflow:hidden" align="center"><font size="4"><b>'
    html += amounts.map{|amount|
      link_with_amount = link_with_token + "&a=#{amount}"
      "<a href=\"#{link_with_amount}\">YES, I'LL CHIP IN $#{amount}</a>"
    }.join('<br><br>')
    html += '</b></font><br><br>'
    html += '<font size="1">To donate another amount, <a href="'+ link_with_token + '">click here</a>.</font>'
    html += '</div>'
  end

  def highest_previous_donation_amount
    amount_in_cents = Transaction.joins(:donation).where(
         "donations.user_id = ? and donations.frequency = 'one_off' and
         transactions.created_at > ? and transactions.amount_in_cents > 0 and
         transactions.successful = true and transactions.refunded = false",
        self.id, 18.months.ago
      ).maximum(:amount_in_cents)
    amount_in_cents ? (amount_in_cents / 100.0).round : nil
  end

  def hpd_for_page_ids(page_ids, max)
    hpd = donations.where('page_id in (?)', page_ids).map(&:amount_in_dollars).max
    return nil unless hpd && hpd > 0
    hpd > max ? max : hpd.round
  end

  def average_is_less_than_half_hpd?(hpd)
    average_amount_in_dollars = Transaction.joins(:donation).where(
         "donations.user_id = ? and donations.frequency = 'one_off' and
         transactions.created_at > ? and transactions.amount_in_cents > 0 and
         transactions.successful = true and transactions.refunded = false",
        self.id, 18.months.ago
      ).average(:amount_in_cents).to_f / 100
    average_amount_in_dollars / hpd < 0.5
  end

  private

  def calculate_hpd(min, max)
    return unless hpd = highest_previous_donation_amount
    hpd = min if hpd < min
    hpd = max if hpd > max
    hpd
  end
end
