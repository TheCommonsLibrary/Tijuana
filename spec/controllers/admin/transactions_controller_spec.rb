require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::TransactionsController do
  include Devise::TestHelpers # to give your spec access to helpers

  before :each do
    sign_in create(:admin_user)
  end

  describe "#index" do
    before(:each) do
      @transactions = [create(:transaction, created_at: Date.parse('2012-01-01')), create(:transaction, created_at: Date.parse('2012-05-29'))]
    Timecop.freeze(Date.parse('2012-05-30'))
    end

    after(:each) do
      Timecop.return
    end

    it "should load transactions from up to two weeks ago by default" do
      from_date = '16-05-2012'
      to_date = '30-05-2012'
      get :index
      response.should be_success
      controller.params[:filter][:from_date].should eq from_date
      controller.params[:filter][:to_date].should eq to_date
      assigns(:transactions).size.should eql 1
      assigns(:transactions).first.created_at.should eql @transactions[1].created_at
    end

    it "should filter transactions by date" do
      from_date = '16-05-2011'
      to_date = '01-02-2012'
      get :index, :filter => {:from_date => from_date, :to_date => to_date }
      response.should be_success
      controller.params[:filter][:from_date].should eq from_date
      controller.params[:filter][:to_date].should eq to_date
      assigns(:transactions).size.should eql 1
      assigns(:transactions).first.created_at.should eql @transactions[0].created_at
    end

    it "should load filter by id" do
      get :index, :query => @transactions[1].id.to_s
      response.should be_success
      assigns(:transactions).size.should eql 1
      assigns(:transactions)[0].txn_id.should eql @transactions[1].id
    end

    it "should allow transactions to be filtered by multiple payment methods" do
      from_date = '16-05-2011'
      to_date = '01-02-2012'
      filter = HashWithIndifferentAccess.new({:payment_methods => ["eftpos"]}).merge(:from_date => from_date, :to_date => to_date)
      Transaction.should_receive(:filter_by).with(filter)
      get :index, :filter => filter
      response.should be_success
    end

    context 'CSV' do
      it "should download transaction" do
        from_date = '16-05-2011'
        to_date = '01-02-2012'
        filter = HashWithIndifferentAccess.new({:from_date => from_date, :to_date => to_date})
        get :index, {:filter => filter, :format => 'csv'}
        response.status.should == 200
        csv = CSV.parse(response.body)
        csv.size.should == 2
        csv[1][6].should match(/2012-01-01/)
      end

      it "should download aggregated transactions" do
        from_date = '16-05-2010'
        to_date = '01-02-2014'
        filter = HashWithIndifferentAccess.new({:group_by => ['frequency'], :from_date => from_date, :to_date => to_date})
        get :index, {:filter => filter, :format => 'csv'}
        response.status.should == 200
        csv = CSV.parse(response.body)
        csv.size.should == 2
        csv[1][0].should == 'one_off'
        csv[1][1].should == '2000'
      end
    end
  end

  describe "refunding a transaction" do
    before(:each) do
      @transaction = create(:transaction)
    end
    
    it "should create a full refund for the specified transaction" do
      put :refund, :id => @transaction.id, :amount_in_dollars => @transaction.amount_in_dollars
      @transaction.reload
      @transaction.refunded?.should == true
      refund = @transaction.refunded_by
      refund.refund_of.should == @transaction
      refund.amount_in_cents.should == -1000
    end
    
    it "should create a partial refund for the specified transaction" do
      put :refund, :id => @transaction.id, :amount_in_dollars => 1.5
      @transaction.reload
      @transaction.refunded?.should == true
      refund = @transaction.refunded_by
      refund.refund_of.should == @transaction
      refund.amount_in_cents.should == -150
      response.should redirect_to admin_transaction_path(@transaction)
    end
    
    it "should not refund more than the transacaction amount" do
      put :refund, :id => @transaction.id, :amount_in_dollars => 2000
      @transaction.reload
      @transaction.refunded?.should == false
      response.should render_template "transactions/show"
    end
    
    it "should not refund zero cents" do
      put :refund, :id => @transaction.id, :amount_in_dollars => 0
      @transaction.reload
      @transaction.refunded?.should == false
      response.should render_template "transactions/show"
    end
    
    it "should not refund a failed transaction" do
      @transaction.update_attributes!(:successful => false)
      put :refund, :id => @transaction.id
      @transaction.refunded?.should == false
      response.should render_template "transactions/show"
    end
    
    it "should not refund anything other than credit card payments" do
      @transaction.donation.update_attributes!(:payment_method => "paypal")
      put :refund, :id => @transaction.id
      @transaction.refunded?.should == false      
      response.should render_template "transactions/show"
    end
    
    it "should not refund the same transaction twice" do
      @transaction.refund!(100)
      put :refund, :id => @transaction.id
      response.should render_template "transactions/show"
    end
    
    it "should not refund a transaction which is already a refund" do
      @transaction.refund!(100)
      put :refund, :id => @transaction.refunded_by.id
      response.should render_template "transactions/show"
    end
    
    it "should not allow volunteers to do refunds" do
      sign_in create(:user, is_volunteer: true)
      put :refund, id: @transaction.id, amount_in_dollars: @transaction.amount_in_dollars
      @transaction.reload
      expect(@transaction).to_not be_refunded
    end
  end
end
