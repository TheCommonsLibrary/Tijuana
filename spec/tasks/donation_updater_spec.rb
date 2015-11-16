require 'spec_helper'
require 'csv'
require_relative "../../lib/tasks/donation_updater"

describe DonationUpdater do
  let(:subject) { DonationUpdater.new('') }
  
  describe "#update_donations" do
    before(:each) do
      @updater = DonationUpdater.new('test-file.csv')
      @user = create(:user, email: 'email@address.com')
      @donation = create(:recurring_donation, user: @user, amount_in_cents: 3000, frequency: 'weekly')
    end

    it "should update donation with new details and email donor" do
      CSV.stub(:foreach).and_yield({'u.id' => @user.id,	'u.email' => @user.email,	'd.id' => @donation.id,	'old amount' => @donation.amount_in_dollars, 'old frequency' => @donation.frequency,'new amount' => '50.5',	'new frequency' => 'monthly'})
      ActionMailer::Base.deliveries = nil

      @updater.update_donations

      @donation = Donation.find(@donation.id)
      @donation.amount_in_dollars.should == 50.5
      @donation.frequency.should == 'monthly'
      ActionMailer::Base.should have(1).deliveries
      mail = ActionMailer::Base.deliveries.last
      mail.should have_body_text(/Your previous details:\s*\$30.00\s*weekly/)
      mail.should have_body_text(/Your amended details will take effect from today:\s*\$50.50\s*monthly/)
      mail.should have_subject('Your Crew donation has been updated')
      mail.should deliver_to('email@address.com')
    end

    context "invalid row" do
      it "should not update donation nor email donor" do
        CSV.stub(:foreach).and_yield({'u.id' => @user.id,	'u.email' => 'a@different.email.com',	'd.id' => @donation.id,	'old amount' => @donation.amount_in_dollars, 'old frequency' => @donation.frequency,'new amount' => '50.5',	'new frequency' => 'monthly'})
        ActionMailer::Base.deliveries = nil

        @updater.update_donations

        @donation = Donation.find(@donation.id)
        @donation.amount_in_dollars.should == 30
        @donation.frequency.should == 'weekly'
        ActionMailer::Base.should have(0).deliveries
      end
    end

  end

  describe "#verify_donation" do
    before(:each) do
      @user = create(:user, id: 5, email: 'an@email.com')
      @donation = create(:donation, user: @user, amount_in_cents: 1000, frequency: 'weekly', id: 15)
    end

    it "should not raise error when the record matches the database" do
      row = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly', 'new frequency' => 'weekly', 'new amount' => '15'} 
      subject.send(:verify_donation, @donation, row)
    end

    it "should raise an error when donation is not for credit card" do
      cc_donation = create(:donation, user: @user, payment_method: 'paypal', amount_in_cents: 1000, frequency: 'annual')
      row = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => cc_donation.id, 'old amount' => '10', 'old frequency' => 'annual'} 
      expect {subject.send(:verify_donation, cc_donation, row) }.to raise_error(RuntimeError, /Donation is not a credit card donation/)
    end

    it "should raise error when the fields do not match" do
      bad_user_id = {'u.id' => 9, 'u.email' => 'an@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly'} 
      expect {subject.send(:verify_donation, @donation, bad_user_id) }.to raise_error(RuntimeError, /User ID does not match/)

      bad_email = {'u.id' => 5, 'u.email' => 'bad@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly'} 
      expect {subject.send(:verify_donation, @donation, bad_email) }.to raise_error(RuntimeError, /email does not match/)

      bad_donation_id = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => '1', 'old amount' => '10', 'old frequency' => 'weekly'} 
      expect {subject.send(:verify_donation, @donation, bad_donation_id) }.to raise_error(RuntimeError, /Donation ID does not match/)

      bad_old_amount = {'u.id' => 5, 'u.email' => 'bad@email.com', 'd.id' => '15', 'old amount' => '3', 'old frequency' => 'weekly'} 
      expect {subject.send(:verify_donation, @donation, bad_old_amount) }.to raise_error(RuntimeError, /Donation email does not match/)

      bad_old_frequency = {'u.id' => 5, 'u.email' => 'bad@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'monthly'} 
      expect {subject.send(:verify_donation, @donation, bad_old_frequency) }.to raise_error(RuntimeError, /Donation email does not match/)
    end
  end

  describe "#validate_row" do
    it "should not raise an exception if the row is valid" do
      row = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly', 'new frequency' => 'weekly', 'new amount' => '15'} 
      subject.send(:validate_row, row)
    end

    context "invalid row" do
      it "should raise an exception if the new frequency is invalid" do
        row = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly', 'new frequency' => '', 'new amount' => '15'} 
        expect {subject.send(:validate_row, row) }.to raise_error(RuntimeError, /New frequency invalid/)

        row = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly', 'new frequency' => 'everyday', 'new amount' => '15'} 
        expect {subject.send(:validate_row, row) }.to raise_error(RuntimeError, /New frequency invalid/)
      end

      it "should raise an exception if the new amount is invalid" do
        row = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly', 'new frequency' => 'weekly', 'new amount' => '0'} 
        expect {subject.send(:validate_row, row) }.to raise_error(RuntimeError, /New amount invalid/)

        row = {'u.id' => 5, 'u.email' => 'an@email.com', 'd.id' => '15', 'old amount' => '10', 'old frequency' => 'weekly', 'new frequency' => 'weekly', 'new amount' => '-1'} 
        expect {subject.send(:validate_row, row) }.to raise_error(RuntimeError, /New amount invalid/)
      end
    end
  end

end
