require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

def create_global_donation_page
  @global_donation_page = create(:page, :page_sequence => create(:static_page_sequence, :name => "Donate"))
  @global_donation_module = create(:donation_module)
  ContentModuleLink.create!(:page => @global_donation_page, :content_module => @global_donation_module)
end

def create_donation_page(campaign)
  @donation_page = create(:page, :page_sequence => create(:page_sequence, campaign: campaign))
  @donation_module = create(:donation_module)
  ContentModuleLink.create!(:page => @donation_page, :content_module => @donation_module)
  @donation_page
end

describe Admin::DonationsController do
  include Devise::TestHelpers # to give your spec access to helpers

  before :each do
    sign_in create(:admin_user)
    MemberCountCalculator.init
  end

  describe "GET #new" do
    render_views
    before{ create(:user, email: AppConstants.umbrella_user_email_address) }

    it{ expect(get :new).to have_http_status(:success) }
    context "with a campaign hidden in admin" do
      let!(:hidden_campaign){ create(:campaign, name: 'hidden campaign', hidden_in_admin: true) }

      it "should not display the campaign in the select list" do
        get :new
        expect(response.body).to_not include(hidden_campaign.name)
      end
    end
  end

  describe "responding to PUT update" do
    before(:each) do
      @user = create(:user)
      @donation_module = create(:donation_module)
      @offline_donation = create(:donation, :user => @user, :payment_method => "cheque")
    end

    describe "update recurring donations" do
      it "should change the frequency of a donation" do
        donation = create(:donation, :amount_in_cents => "1234500", :frequency => "weekly")
        put :update, {:id => donation.id, :donation => {:frequency => "monthly"}}
        donation.reload
        donation.frequency.should == "monthly"
      end

      it "should change the amount in a donation" do
        donation = create(:donation, :frequency => "weekly")
        donation.amount_in_dollars = "45623"
        put :update, {:id => donation.id, :donation => {:amount_in_dollars => "33213"}}
        donation.reload
        donation.amount_in_dollars.should == 33213.0
      end

      it "should redirect back to the user admin page on update" do
        donation = create(:donation, :user => @user, :frequency => "weekly")
        put :update, {:id => donation.id}

        response.should redirect_to(edit_admin_user_path(donation.user))
      end

      it 'should add a flash error and donation should remain untouched' do
        donation = create(:donation)
        put :update_credit_card_identifiers, {id: donation.id, donation: {frequency: 'weekly', amount_in_dollars: '100', card_last_four_digits: 1234, card_expiry_month: 'w', card_expiry_year: 1990}}
        donation.reload.card_expiry_month.should_not == 'w'
        flash[:error].should eql 'The donation has not been updated. Please fix the errors below.'
      end

      it 'should update the donation and redirect to the edit user page' do
        donation = create(:donation)
        put :update_credit_card_identifiers, {id: donation.id, donation: {frequency: 'weekly', amount_in_dollars: '100', card_last_four_digits: '1234', card_expiry_month: 2, card_expiry_year: 1990}}
        donation.reload.card_last_four_digits.should == '1234'
        donation.reload.card_expiry_month.should == 2
        donation.reload.card_expiry_year.should == 1990
        response.should redirect_to(edit_admin_user_url(donation.user_id))
      end
    end

    describe "update offline donations" do
      before :each do
        Timecop.freeze(Time.utc('2012-07-30'))
      end

      after :each do
        Timecop.return
      end

      it "should redirect to the transactions admin page" do
        create(:transaction, :donation => @offline_donation, :created_at => Time.now)
        create(:page, :page_sequence => create(:static_page_sequence, :name => "Donate"))

        put :update, {:id => @offline_donation.id, :donation => {:amount_in_dollars => "100"}, :transaction => {:created_at => Time.now}, :campaign => ""}

        response.should redirect_to(admin_transactions_path)
      end

      it "should change the amount of offline donation, page_id and created at" do

        campaign = create(:campaign)
        campaign.find_or_create_offline_donation_page

        transaction = create(:transaction, :donation => @offline_donation, :created_at => Time.now)
        t = Time.utc('2013-02-09')

        put :update, {:id => @offline_donation.id, :donation => {:amount_in_dollars => "1234"}, :transaction => {:created_at => t}, :campaign => campaign.id}

        @offline_donation.reload.amount_in_dollars.should == 1234.0
        @offline_donation.reload.page.name.should == 'Offline Donations'
        transaction.reload.amount_in_dollars.should == 1234.0
        transaction.reload.created_at = t
      end

      context "should not update donation and related transaction" do
        it "should add an error if created_at date for transaction not provided" do
          create_global_donation_page
          create(:transaction, :donation => @offline_donation, :created_at => Time.now, :message => "Offline donation ##{@offline_donation.id}")

          put :update, {:id => @offline_donation.id, :donation => {:amount_in_dollars => "100"}, :transaction => {:created_at => ''}}

          donation = assigns(:donation)
          transaction = assigns(:transaction)
          donation.reload.amount_in_dollars.should_not eq 100.0
          transaction.error_on(:created_at).first.should == "date can't be blank"
        end
      end
    end

    describe "update one_off donations" do
      it "should redirect to the transaction admin page" do
        oneoff_donation = create(:donation, :frequency => "one_off")
        put :update, {:id => oneoff_donation.id}
        response.should redirect_to(admin_transactions_path)
      end

      it "should change the page id of one_off donation" do
        oneoff_donation = create(:donation, :frequency => "one_off")
        page = create(:page_with_parent)
        put :update, {:id => oneoff_donation.id, :donation => {:page_id => page.id}}
        oneoff_donation.reload.page_id.should == page.id
      end
    end

  end

  describe "offline donations" do
    def valid_params(page_id=nil, user_id=nil)
      {
        :page_id => page_id,
        :user_id => user_id,
        :amount_in_dollars => "10.999",
        :payment_method => "cash",
        :identifier => "666, Rock n Roll Road"
      }
    end

    let(:user) { create(:user) }
    let(:donation_page) { create(:page_with_parent) }
    let(:donation_module) { create(:donation_module) }

    before :each do
      Timecop.freeze(Time.utc('2012-07-30'))
      ActionMailer::Base.deliveries = []
      ContentModuleLink.create!(:page => donation_page, :content_module => donation_module)
    end

    after :each do
      Timecop.return
    end

    subject do
      post :create, :donation => valid_params(donation_page.id, user.id), :transaction => {:created_at => Time.now}, :campaign => donation_page.page_sequence.campaign.id
      assigns(:donation)
    end

    it { should_not be_new_record }
    its(:user) { should == user }
    it('should have correct page name') { subject.page.name.should == "Offline Donations" }
    it('should have a content module with the correct class') { subject.content_module.class.should == DonationModule}
    its(:amount_in_cents) { should == 1099 }
    its(:identifier) { should eql "666, Rock n Roll Road" }
    its(:last_donated_at) { should eql Time.utc('2012-07-30') }

    context 'campaign is not provided' do
      it "should default to the global donation" do
        create_global_donation_page()

        post :create, :donation => valid_params("", user.id), :transaction =>{ :created_at => Time.now }, :campaign => ""

        donation = assigns(:donation)
        donation.should_not be_new_record
        donation.content_module.should == @global_donation_module
      end
    end

    context 'campaign is provided' do
      let!(:campaign) { create(:campaign) }
      before do
        page_sequence = create(:page_sequence, :campaign => campaign)
        petition_page = create(:page, :page_sequence => page_sequence, :name => "petition")
        petition_module = create(:petition_module)
        ContentModuleLink.create!(:page => donation_page, :content_module => donation_module)
        ContentModuleLink.create!(:page => petition_page, :content_module => petition_module)
      end

      it "should generate donation with page_id that is offline donation  for the selected campaign" do
        post :create, :donation => valid_params("", user.id), :transaction =>{ :created_at => Time.now }, :campaign => campaign.id
        donation = assigns(:donation)
        donation.should_not be_new_record
        donation.page.name.should == 'Offline Donations'
        donation.page.page_sequence.campaign.should == campaign
      end

      it 'should create a user activity event for the offline donation' do
        post :create, :donation => valid_params("", user.id), :transaction =>{ :created_at => Time.now }, :campaign => campaign.id
        donation = assigns(:donation)
        expect(
          UserActivityEvent.where({
            user_id: user.id,
            user_response: donation.transactions.first
          }).count
        ).to eq(1)
      end
    end

    context 'should not create donation and related transaction' do
      context 'user id is invalid' do
        it "should add an error" do
          create_global_donation_page()

          post :create, :donation => valid_params(donation_page.id, -1), :transaction => {:created_at => Time.now}

          donation = assigns(:donation)
          donation.should be_new_record
          donation.errors[:user].first.should == "can't be blank"
        end
      end

      context 'created_at date for transaction not provided' do
        it "should add an error" do
          create_global_donation_page()

          post :create, :donation => valid_params(donation_page.id, user.id), :transaction => {:created_at => ''}

          transaction = assigns(:transaction)
          transaction.errors_on(:created_at).first.should == "date can't be blank"
        end
      end
    end

    it 'should send email to user if transaction is succeeded' do
      create_global_donation_page()

      post :create, :donation => valid_params(donation_page.id, user.id), :transaction => {:created_at => Time.now}, :campaign => donation_page.page_sequence.campaign.id

      ActionMailer::Base.deliveries.size.should == 1

      offline_donation_receipt_email = ActionMailer::Base.deliveries.first
      offline_donation_receipt_email.from.first.should == "donations@getup.org.au"
      offline_donation_receipt_email.to.first.should == user.email
      offline_donation_receipt_email.body.should =~ /cash/
    end

    it 'should NOT send email to user if transaction is not succeeded' do
      create_global_donation_page()

      post :create, :donation => valid_params(donation_page.id, user.id), :transaction => {:created_at => ''}

      ActionMailer::Base.deliveries.size.should == 0

    end
  end

  describe "cancelling a recurring donation" do
    before(:each)do
      @donation = create(:donation, :frequency => "monthly")
      create(:transaction, donation: @donation)
      ActionMailer::Base.deliveries = []
    end

    it "should cancel the donation and record the reason" do
      put :cancel_recurring, :id => @donation.id, donation: {cancel_reason: 'retired'}
      @donation.reload
      expect(@donation.active).to eq(false)
      expect(@donation.cancel_reason).to eq('retired')
    end

    it "should redirect to admin user edit page by default" do
      put :cancel_recurring, :id => @donation.id, donation: {cancel_reason: 'retired'}
      response.should redirect_to(edit_admin_user_path(@donation.user))
    end

    it "should send the cancellation email" do
      put :cancel_recurring, :id => @donation.id, donation: {cancel_reason: 'retired'}

      ActionMailer::Base.deliveries.size.should == 1
      offline_donation_receipt_email = ActionMailer::Base.deliveries.first
      offline_donation_receipt_email.subject.should =~ /Cancelled GetUp Crew Donation/
    end

    context "with redirect override" do
      it "should redirect to admin transaction page" do
        put :cancel_recurring, :id => @donation.id, redirect_to: admin_transaction_path(@donation.transactions.first), donation: {cancel_reason: 'retired'}
        response.should redirect_to("/admin/transactions/#{@donation.transactions.first.id}")
      end
    end
  end

  describe "listing flagged donations" do
    it "should display flagged donations" do
      donation = create(:flagged_donation)

      get :flagged

      response.should be_success
      assigns(:flagged_donations).size.should eql 1
      assigns(:flagged_donations).should include(donation)
    end

    it "should not display flagged donations which have been dismissed" do
      flagged_donation = create(:flagged_donation)
      flagged_unflagged_donation = create(:flagged_donation, :flagged_since => nil)

      get :flagged

      response.should be_success
      assigns(:flagged_donations).size.should eql 1
      assigns(:flagged_donations).should include(flagged_donation)
      assigns(:flagged_donations).should_not include(flagged_unflagged_donation)
    end
  end

  describe "dismissing donations" do
    it "should dismiss recurring donations" do
      fake_today = Date.civil(2011, 02, 03).to_time
      Time.stub(:now) { fake_today }
      donation = create(:flagged_donation)
      donation1 = create(:flagged_donation)

      put :dismiss_recurring_donations, :donations => {donation.id.to_s => {"dismissed" => "1"}, donation1.id.to_s => {"dismissed" => "1"}}

      response.should redirect_to(flagged_admin_donations_path(:selected => 0))
      flash[:notice].should eql "The selected donations have been dismissed."
      donation.reload.dismissed_at.should_not be_nil
      donation1.reload.dismissed_at.should_not be_nil
    end

    it "should flash error in case of a failed update" do
      put :dismiss_recurring_donations, :donations => {"nada" => {"dismissed" => "1"}}

      response.should redirect_to(flagged_admin_donations_path(:selected => 0))
      flash[:error].should eql "No donations were dismissed."
    end

    it "should flash error if no donation has been selected" do
      put :dismiss_recurring_donations

      response.should redirect_to(flagged_admin_donations_path)
      flash[:warning].should eql "No donations have been selected."
    end

    it "should dismiss failed new donations" do
      fake_today = Date.civil(2011, 02, 03).to_time
      Time.stub(:now) { fake_today }
      donation = create(:flagged_donation)
      donation1 = create(:flagged_donation)
      put :dismiss_failed_new_donations, :donations => {donation.id.to_s => {"dismissed" => "1"}, donation1.id.to_s => {"dismissed" => "1"}}
      response.should redirect_to(flagged_admin_donations_path(:selected => 1))
      flash[:notice].should eql "The selected donations have been dismissed."
      donation.reload.dismissed_at.should_not be_nil
      donation1.reload.dismissed_at.should_not be_nil
    end
  end

end
