require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Transaction do
  before do
    ActionMailer::Base.deliveries = []
    UserMailer.stub(:welcome_to_getup_email) { double(:deliver => nil) }
  end

  describe "amount in cents" do
    it "should convert into dollars" do
      amount_in_cents = 101
      Transaction.convert_to_dollars(amount_in_cents).should eql 1.01
    end
  end

  describe "csv data filter_by" do
    it "should use an optimized query to load the transactions from the database" do
      Timecop.freeze('2012-03-15') do
        donation = create(:donation, :amount_in_cents => 2500)
        transaction1 = Transaction.create!(:donation => donation, :successful => true, :created_at => Date.parse('2012-03-15'))
        transaction2 = Transaction.create!(:donation => donation, :successful => true, :created_at => Date.parse('2012-03-15'))
        transaction3 = Transaction.create!(:donation => donation, :successful => true, :created_at => Date.parse('2012-03-13'))
        other_user = create(:user)
        transaction4 = Transaction.create!(:donation => create(:donation, :amount_in_cents => 2500, :user => other_user), :successful => true, :created_at => Date.parse('2012-04-30'))

        transactions = Transaction.filter_by(:from_date => '14-03-2012', :to_date => '16-03-2012').map(&:txn_id)
        transactions.size.should eql 2
        transactions.should include(transaction1.id)
        transactions.should include(transaction2.id)

        transactions = Transaction.filter_by(:user_id => other_user.id).map(&:user_id)
        transactions.size.should eql 1
        transactions.should include(other_user.id)
      end
    end
  end

  describe "filtering" do
    context "existing transactions" do
      before(:each) do
        payment_methods = [:eftpos, :cash, :money_order, :bank_cheque, :paypal, :creditcard, :cheque]
        @transactions = payment_methods.inject([]) do |acc, method|
          donation = create(:donation, :payment_method => method)
          acc << create(:transaction, :donation => donation, :successful => false)
          acc
        end
      end
      it "should allow transactions to be filtered by multiple payment methods" do

        transactions = Transaction.filter_by(:payment_methods => [:eftpos]).all
        transactions.size.should eql 1
        transactions[0].txn_id.should eql @transactions.select { |t| t.donation.payment_method.to_sym == :eftpos }[0].id

        transactions = Transaction.filter_by(:payment_methods => [:paypal, :cheque]).all
        transactions.size.should eql 2
        transactions.map(&:payment_method).should include("paypal")
        transactions.map(&:payment_method).should include("cheque")

        transactions = Transaction.filter_by(:payment_methods => ['']).all
        transactions.size.should eql 7
      end

      it "should allow transactions to be filtered by status" do
        @transactions.first.update_attribute(:successful, true)
        successful_transaction_1 = @transactions.first
        @transactions.last.update_attribute(:successful, true)
        successful_transaction_2 = @transactions.last

        transactions = Transaction.filter_by({:status => "successful"}).all
        transactions.size.should eql 2
        transactions.select { |transaction| transaction.txn_id == successful_transaction_1.id }.should_not be_empty
        transactions.select { |transaction| transaction.txn_id == successful_transaction_2.id }.should_not be_empty
      end

      it "should allow transactions to be filtered minimum amount" do
        @transactions.first.update_attribute(:amount_in_cents, 100_000)
        large_transaction_1 = @transactions.first
        @transactions.last.update_attribute(:amount_in_cents, 100_000)
        large_transaction_2 = @transactions.last

        transactions = Transaction.filter_by({:minimum_dollars => "999"}).all
        transactions.size.should eql 2
        transactions.select { |transaction| transaction.txn_id == large_transaction_1.id }.should_not be_empty
        transactions.select { |transaction| transaction.txn_id == large_transaction_2.id }.should_not be_empty
      end

      it "should allow transactions to be filtered maximum amount" do
        @transactions.first.update_attribute(:amount_in_cents, 100)
        small_transaction_1 = @transactions.first
        @transactions.last.update_attribute(:amount_in_cents, 100)
        small_transaction_2 = @transactions.last

        transactions = Transaction.filter_by({:maximum_dollars => "2"}).all
        transactions.size.should eql 2
        transactions.select { |transaction| transaction.txn_id == small_transaction_1.id }.should_not be_empty
        transactions.select { |transaction| transaction.txn_id == small_transaction_2.id }.should_not be_empty
      end

      it "should not filter transactions by amount if the amounts are blank" do
        transactions = Transaction.filter_by({:maximum_dollars => "", :minimum_dollars => ""}).all
        transactions.size.should eql @transactions.length
      end

      it "should allow transactions to be filtered by donor's email" do
        donor = create(:user)
        another_donor = create(:user)
        @transactions.first.donation.update_attribute(:user, donor)
        transaction_1 = @transactions.first
        @transactions.last.donation.update_attribute(:user, donor)
        transaction_2 = @transactions.last
        @transactions[1].donation.update_attribute(:user, another_donor)

        transactions = Transaction.filter_by({:user_email => donor.email}).all
        transactions.size.should eql 2
        transactions.select { |transaction| transaction.txn_id == transaction_1.id }.blank?.should be false
        transactions.select { |transaction| transaction.txn_id == transaction_2.id }.blank?.should be false
      end

    end
  end

  describe "date filtering" do
    it "should filter transactions by from date" do
      Timecop.freeze(Date.parse('2012-03-15')) do
        transaction_1 = create(:transaction, :created_at => Time.local(2012, 3, 14, 23, 59, 0))
        transaction_2 = create(:transaction, :created_at => Time.local(2012, 3, 15, 0, 1, 0))

        transactions = Transaction.filter_by({:from_date => '15-03-2012'})
        transactions.size.should eql 1
        transactions.first.txn_id.should eql transaction_2.id
      end
    end

    it "should filter transactions by to date" do
      Timecop.freeze(Date.parse('2012-03-15')) do
        transaction_1 = create(:transaction, :created_at => Time.local(2012, 3, 14, 23, 59, 0))
        transaction_2 = create(:transaction, :created_at => Time.local(2012, 3, 15, 0, 1, 0))

        transactions = Transaction.filter_by({:to_date => '14-03-2012'})
        transactions.size.should eql 1
        transactions.first.txn_id.should eql transaction_1.id
      end
    end
  end

  describe "grouping" do
    it "should allow transactions to be grouped by year, month, campaign and frequency" do
      payment_methods = [:eftpos, :cash, :money_order, :bank_cheque, :paypal, :creditcard, :cheque]
      @created_at = Time.local(2011, 12, 28, 0, 0, 1)
      @transactions = payment_methods.inject([]) do |acc, method|
        donation = create(:donation, :payment_method => method, :frequency => :one_off)
        acc << create(:transaction, :donation => donation, :successful => false, :amount_in_cents => 1000, :created_at => @created_at)
        acc
      end

      donation = create(:donation, :payment_method => :cash, :frequency => :one_off)
      create(:transaction, :donation => donation, :successful => false, :amount_in_cents => 1000, :created_at => Time.local(2012, 12, 28, 0, 0, 1))

      transactions = Transaction.filter_by(:group_by => [:year_month, :campaign, :frequency]).all
      transactions.size.should eql 2
      transactions[0].year.should eql 2012
      transactions[0].month.should eql 12
      transactions[0].frequency.should eql "one_off"
      transactions[0].total.to_i.should eql 1000

      transactions[1].year.should eql @created_at.year
      transactions[1].month.should eql @created_at.month
      transactions[1].frequency.should eql "one_off"
      transactions[1].total.to_i.should eql 7000
    end
  end

  describe "#offline_donation?" do
    it "should validate created_at date for transaction for offline_donation" do
      Timecop.freeze(Time.utc(2013, 02, 01)) do
        offline_donation = create(:donation, :payment_method => "cheque")
        Transaction.new(:donation => offline_donation, :created_at => Time.now, :message => "Offline donation ##{offline_donation}.id").should be_valid
        Transaction.new(:donation => offline_donation, :created_at => '', :message => "Offline donation ##{offline_donation.id}").should_not be_valid
        Transaction.new(:donation => offline_donation, :created_at => '', :message => "Offline donation ##{offline_donation.id}").error_on(:created_at).first.should == "date can't be blank"
      end
      Timecop.return
    end

    it "should not validate created_at date for transaction for non offline donation" do
      Transaction.new(:donation => create(:donation), :created_at => '', :message => "Successful").should be_valid
    end
  end
end
