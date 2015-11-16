require 'spec_helper'
require 'rake'

describe "manual_emails_sent:import rake task" do
  include_context "capture_system_io"

  today = Time.now
  let!(:weekly_donor) { FactoryGirl.create(:user, email: "weekly_donor@user.com",
                                           notes: "January 18, 2015 emailed re: expiry AM") }
  let!(:monthly_donor) { FactoryGirl.create(:user, email: "monthly_donor@user.com",
                                           notes: "January 30, 2015 emailed re: consecutive failures AM\n"\
                                                  "January 30, 2015 emailed re: insufficient fund AM\n"\
                                                  "February 3, 2015 called, na, emailed re: follow-up on consecutive failures AM") }
  let!(:annual_donor) { FactoryGirl.create(:user, email: "annual_donor@user.com",
                                           notes: "March 4, 2015 emailed re: donation cancellation warning AM") }
  let!(:weekly_failed_donation) { FactoryGirl.create(:donation,
                                         :user => weekly_donor,
                                         :card_number => PaymentGateways::CARD_FAILURE,
                                         :frequency => "weekly",
                                         :card_expiry_month => "04",
                                         :card_expiry_year => "26",
                                         :assigned_to => 'Alexander Mills',
                                         :last_tried_at => today) }
  let!(:monthly_failed_donation) { FactoryGirl.create(:donation,
                                         :user => monthly_donor,
                                         :card_number => PaymentGateways::CARD_FAILURE,
                                         :frequency => "monthly",
                                         :card_expiry_month => "04",
                                         :card_expiry_year => "26",
                                         :assigned_to => 'Alexander Mills',
                                         :last_tried_at => today) }
  let!(:annual_failed_donation) { FactoryGirl.create(:donation,
                                         :user => annual_donor,
                                         :card_number => PaymentGateways::CARD_FAILURE,
                                         :frequency => "annual",
                                         :card_expiry_year => "26",
                                         :assigned_to => 'Alexander Mills',
                                         :last_tried_at => today) }

  let!(:weekly_failed_transaction_1) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => today) }
  let!(:weekly_failed_transaction_2) { FactoryGirl.create(:failed_transaction, :donation => weekly_failed_donation, :created_at => today - 1.week) }
  
  let!(:monthly_failed_transaction_1) { FactoryGirl.create(:failed_transaction, :donation => monthly_failed_donation, :created_at => today) }
  let!(:monthly_failed_transaction_2) { FactoryGirl.create(:failed_transaction, :donation => monthly_failed_donation, :created_at => today - 1.month) }

  let!(:annual_failed_transaction_1) { FactoryGirl.create(:failed_transaction, :donation => annual_failed_donation, :created_at => today) }
  let!(:annual_failed_transaction_2) { FactoryGirl.create(:failed_transaction, :donation => annual_failed_donation, :created_at => today - 1.year) }

  before :each do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake::Task.define_task(:environment)
    load "#{Rails.root}/lib/tasks/track_manual_emails_sent.rake"
  end

  it "should insert to sent_trigger_emails table based on user's notes" do
    @rake["manual_emails_sent:import"].invoke
    SentTriggerEmail.all.map(&:user).uniq.count.should == 3
    SentTriggerEmail.all.size.should == 4
  end

  context "if rerun" do
    before{ TrackManualEmailsSent.new.import }

    it "should raise" do
      expect{ @rake["manual_emails_sent:import"].invoke }.to raise_error(/There are already \d* SentTriggerEmail records/)
    end
  end

end
