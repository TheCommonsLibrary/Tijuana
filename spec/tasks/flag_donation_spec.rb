require 'spec_helper'

require 'rake'
describe "should flag donations that needs attention" do
  before :each do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake::Task.define_task(:environment)
    load "#{Rails.root}/lib/tasks/flag_donation.rake"
  end

  it "should unflag donations" do
    expired_donation = create(:donation_without_validation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => 'monthly',
                                             :card_expiry_month => '2', :card_expiry_year => '2011', :flagged_since => Date.today, :flagged_because => 'Expired Credit Card: 2/2011')

    @rake["flag_donations:unflag"].invoke

    expired_donation.reload.flagged_since.should be_nil
    expired_donation.flagged_because.should be_nil
  end

  it "should unflag donations which are expired but has a subsequent successful transaction" do
    flagged_but_incorrect = create(:donation_without_validation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => 'monthly',
                                             :card_expiry_month => '2', :card_expiry_year => '2011', :flagged_since => Date.yesterday, 
                                             :flagged_because => 'Expired Credit Card: 2/2011', :last_donated_at => Date.today)

    expired = create(:donation_without_validation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => 'monthly',
                                             :card_expiry_month => '2', :card_expiry_year => '2011', :flagged_since => Date.yesterday, 
                                             :flagged_because => 'Expired Credit Card: 2/2011')
    not_flagged = create(:donation, :card_number => PaymentGateways::CARD_SUCCESS, :frequency => "monthly",
                       :card_expiry_month => Time.now.month, :card_expiry_year => Time.now.year + 2)

    @rake["flag_donations:correct_false_positives"].invoke

    flagged_but_incorrect.reload

    flagged_but_incorrect.flagged_since.should be_nil
    flagged_but_incorrect.flagged_because.should be_nil

    expired.reload.flagged_since.should_not be_nil
    expired.reload.flagged_because.should_not be_nil

    not_flagged.reload.flagged_since.should be_nil
    not_flagged.reload.flagged_because.should be_nil
  end
end
