When /^"([^"]*)" has an active flagged donation$/ do |email|
  two_weeks_from_now = 2.weeks.from_now
  tomorrow = Date.tomorrow
  user = User.find_by_email(email)

  create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "monthly",
                 :card_expiry_month => two_weeks_from_now.month, :card_expiry_year => two_weeks_from_now.year,
                 :user => user, :flagged_since => Time.now, :flagged_because => "Expiring Credit Card")
  create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "monthly",
                 :card_expiry_month => tomorrow.month, :card_expiry_year => tomorrow.year,
                 :user => user, :flagged_since => Time.now, :flagged_because => "Expiring Credit Card")
end

Then /^I should see the following flagged donations:$/ do |table|
  within("table.donations") do
    table.hashes.each_with_index do |row, idx|
      within("tr:nth-child(#{idx+2})") do
        row.each do |header, value|
          actual_value = page.find("td.#{header.downcase.gsub(' ', '-')}").text
          expected_value = value
          raise "Expected #{expected_value} #{header} but was #{actual_value}" if actual_value != expected_value
        end
      end
    end
  end
end

When /^I dismiss all donations$/ do
  within("table.donations") do
    #page.check("input[type=checkbox]")
    page.all("input[type=checkbox]").each do |e|
      e.set true
    end
    #page.all("input[type=checkbox]").map(&:check)
  end
  click_button("Dismiss selected")
end
When /^I should not see any donations to be dismissed$/ do
  step %Q{I should see "There are no flagged recurring donations at this time."}
end