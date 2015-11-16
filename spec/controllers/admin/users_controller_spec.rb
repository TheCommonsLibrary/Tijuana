require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::UsersController do
  include Devise::TestHelpers # to give your spec access to helpers

  before :each do
    @user = create(:user)
    @admin_user = create(:admin_user)
    sign_in @admin_user
  end

  describe "responding to POST tag_users", :vcr do
    without_transactional_fixtures do
      it "should tag users based on the specified list" do
        list = List.new
        list.set_country_rule(:country_iso => "AU")
        list.save!

        aussie = create(:user, :country_iso => "AU")
        german = create(:user, :country_iso => "DE")

        post :add_tags, :list_id => list.id, :tags => " red, blue "

        aussie.reload.tag_list.should == ["red", "blue"]
        german.reload.tag_list.should == []
      end
    end
  end

  describe "adding an external action" do
    describe 'using an existing page id' do
      context 'when page has a member value type' do
        before(:each) do
          @list = List.new
          @list.save!
          @page = create(:page_with_parent, member_value_type: 'voice')
        end

        it "should error on page ids that don't exist" do
          ListIntermediateResult.create(:list => @list, :data => {:size => 0})
          response = post :add_external_actions, :list_id => @list.id, :external_action_page_id => '999919999', :format => 'json'
          json = JSON.parse(response.body)
          json['error']['external_action_page_id'].should_not be_nil
        end

        it "should error when no page id supplied" do
          ListIntermediateResult.create(:list => @list, :data => {:size => 0})
          response = post :add_external_actions, :list_id => @list.id, :format => 'json'
          json = JSON.parse(response.body)
          json['error']['external_action_page_id'].should_not be_nil
        end

        it "should error when list is too big" do
          ListIntermediateResult.create(:list => @list, :data => {:size => 100_001})
          response = post :add_external_actions, :list_id => @list.id, :external_action_page_id => @page.id, :format => 'json'
          json = JSON.parse(response.body)
          json['error']['external_action_page_id'].should_not be_nil
        end

        it "should add external actions to users based on the specified list" do
          ListIntermediateResult.create(:list => @list, :data => {:size => 1000})
          Delayed::Job.delete_all
          response = post :add_external_actions, :list_id => @list.id, :external_action_page_id => @page.id, :format => 'json'
          Delayed::Job.last.handler.should include("AddExternalActionsJob")
          json = JSON.parse(response.body)
          json['page_path'].should == edit_admin_page_path(@page.id).to_s
        end
      end

      context 'when page does not have a member value type' do
        before(:each) do
          @list = create(:list)
          @page = create(:page_with_parent)
        end

        it 'should prevent creating external action' do
          ListIntermediateResult.create(:list => @list, :data => {:size => 0})
          Delayed::Job.delete_all

          response = post :add_external_actions, :list_id => @list.id, :external_action_page_id => @page.id, :format => 'json'
          Delayed::Job.count.should == 0
          json = JSON.parse(response.body)
          json['error']['external_action_page_id'].should_not be_nil
        end
      end
    end

    describe 'creating a new page' do
      before(:each) do
        @list = create(:list)
      end

      it 'should error when no page name supplied' do
        ListIntermediateResult.create(:list => @list, :data => {:size => 0})
        response = post :create_page_add_external_actions, :list_id => @list.id, :format => 'json'
        json = JSON.parse(response.body)
        json['error']['page_name'].should_not be_nil
      end

      it 'should error when no page sequence supplied' do
        ListIntermediateResult.create(:list => @list, :data => {:size => 0})
        response = post :create_page_add_external_actions, :list_id => @list.id, :page_name => 'Page Name', :format => 'json'
        json = JSON.parse(response.body)
        json['error']['page_sequence_name'].should_not be_nil
      end

      it 'should error when page sequence already exists' do
        ListIntermediateResult.create(:list => @list, :data => {:size => 0})
        page_sequence = create(:page_sequence)
        response = post :create_page_add_external_actions, :list_id => @list.id, :page_sequence_name => page_sequence.name, :format => 'json'
        json = JSON.parse(response.body)
        json['error']['page_sequence_name'].should_not be_nil
      end

      it 'should create new page and add external actions to users based on the specified list' do
        ListIntermediateResult.create(:list => @list, :data => {:size => 1000})
        Delayed::Job.delete_all

        campaign = create(:campaign)
        params = {
            :list_id => @list.id,
            :page_name => 'Page Name',
            :page_sequence_name => 'Page Sequence Name',
            :campaign_id => campaign.id,
            :member_value_type => 'voice',
            :format => 'json'
        }

        response = post :create_page_add_external_actions, params

        page = Page.find_by_name('Page Name')
        page_sequence = PageSequence.find_by_name('Page Sequence Name')

        page_sequence.campaign.should == campaign
        page.page_sequence.should == page_sequence

        Delayed::Job.last.handler.should include("AddExternalActionsJob")
        json = JSON.parse(response.body)
        json['page_path'].should == edit_admin_page_path(page.id).to_s
      end
    end

  end

  describe "responding to GET index" do
    context "initial page loads" do
      it "should display all users" do
        get :index
        assigns(:users).should include(@user)
        assigns(:users).should include(@admin_user)
        response.should render_template("users/index")
      end
    end

    it "should search for users by email, first_name, last_name and is_admin with exact match" do
      params = {query_option: 'email', query: 'admin-hello@email.com', first_name: 'rich', last_name: 'you', admin_only: '1', exact_match: '1'}
      get :index, params
      user = create(:admin_user, email: 'admin-hello@email.com', first_name: 'rich', last_name: 'you')
      assigns(:users).should eq [user]
      response.should render_template("users/index")
    end
  end

  describe "get transactions for user" do
    before :each do
      Timecop.freeze(Date.parse('2012-04-30'))
      25.times do
        create(:transaction, :donation => create(:donation, :user => @user), :successful => true, :created_at => Time.local(2012, 04, 01), :amount_in_cents => 101)
      end
    end

    after :each do
      Timecop.return
    end

    it "should paginate transactions" do
      get :transactions, :id => @user.id
      assigns(:transactions).size.should eql Admin::UsersController::PAGE_SIZE
    end

    it "should count transactions" do
      get :edit, :id => @user.id
      assigns(:transaction_count).should eql 25
    end

    it "should sum of successful transactions" do
      get :edit, :id => @user.id
      assigns(:transaction_sum).should eql 25.25
    end
  end

  describe "responding to POST create" do
    describe "with valid params" do
      it "should create a user and redirect to the index page" do
        post :create, :user => {:email => "hello@kittypetition.org"}
        @user = assigns(:user)
        @user.should_not be_new_record
        @user.encrypted_password.should be_nil
        response.should redirect_to(admin_users_path)
      end
    end

    describe "with invalid params" do
      it "should not save the user and re-render the form" do
        post :create, :user => nil
        @user = assigns(:user)
        @user.should be_new_record
        response.should render_template("users/new")
      end
    end

    describe "responding to PUT update" do
      describe "with valid params" do
        it "should update a user and redirect to the edit user page" do
          put :update, {:id => @user.id, :user => {:email => "hello@kittypetition.org"}}
          @user.reload
          @user.email.should == "hello@kittypetition.org"
          response.should redirect_to(edit_admin_user_path(@user))
        end
      end

      describe "with invalid params" do
        it "should not save the user and re-render the form" do
          put :update, {:id => @user.id, :user => {:email => ""}}
          response.should render_template("users/edit")
        end
      end
    end
  end

  describe "responding to DELETE destroy" do
    it "should delete the user then redirect to users index" do
      delete :destroy, :id => @user.id
      @user.reload
      @user.should be_deleted
      response.should redirect_to(admin_users_path)
    end
  end

  describe "changing roles" do
    it "should change roles if current user is admin" do
      request.env['warden'] = double(Warden, :authenticate => create(:user, :is_admin => true),
                                   :authenticate! => create(:user, :is_admin => true),
                                   :authenticate? => true,
                                   :session => create(:user, :is_admin => true))

      post :create, :user => {:email => "hello@kittypetition.org", :is_admin => true, :is_volunteer => true}
      user = assigns(:user).reload
      user.should be_is_admin
      user.should be_is_volunteer

      user.update_attributes!(:is_admin => false, :is_volunteer => false)

      put :update, :id => user.id, :user => {:email => "hello@kittypetition.org", :is_admin => true, :is_volunteer => true}
      user = assigns(:user).reload
      user.should be_is_admin
      user.should be_is_volunteer
    end

    it "should not change roles if current user is volunteer" do
      request.env['warden'] = double(Warden, :authenticate => create(:user, :is_volunteer => true, :is_admin => false),
                                   :authenticate! => create(:user, :is_volunteer => true, :is_admin => false),
                                   :authenticate? => true,
                                   :session => create(:user, :is_volunteer => true, :is_admin => false))

      expect { post :create, :user => {:email => "hello@kittypetition.org", :is_admin => true, :is_volunteer => true} }.to raise_exception(/custom_failure/)

      expect { put :update, :id => create(:user).id, :user => {:email => "hello@kittypetition.org", :is_admin => true, :is_volunteer => true} }.to raise_exception(/custom_failure/)
      user = assigns(:user).reload
      user.should_not be_is_admin
      user.should_not be_is_volunteer
    end
  end

  describe "downloading user transaction report" do
    it "should render a stats table for transactions for this user" do
      user = create(:user)
      donation = create(:donation, :user => user)
      campaign_txn = campaign_donation = donation.transactions.create!(
          :created_at => Date.parse("2010-01-01").to_time,
          :settled_on => Date.parse("2010-01-02"),
          :successful => false,
          :txn_ref => "TXNREF",
          :bank_ref => 12345,
          :amount_in_cents => donation.amount_in_cents
      )

      static_page = create(:page, :page_sequence => create(:page_sequence, :campaign => nil))
      static_donation = create(:paypal_donation, :user => user, :page => static_page)
      static_txn = static_donation.transactions.create!(
          :created_at => Date.parse("2010-11-01").to_time,
          :settled_on => Date.parse("2010-11-02"),
          :successful => true,
          :txn_ref => "TXNREF",
          :amount_in_cents => donation.amount_in_cents
      )

      get :transaction_report, :id => user.id
      csv = response.body.split("\n")
      csv.size.should == 3
    end
  end

  describe 'bulk import users using a CSV file' do
    it 'should accept a CSV file with valid content' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'bulk_users_with_id_email.csv'), 'text/csv')
      post :import, :csv => file
      flash[:error].should be_nil
    end

    it 'should show an error if the file type is invalid' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'a_text_file.txt'), 'text/plain')
      post :import, :csv => file
      flash[:error].should == 'Invalid file type, please upload a .csv file.'
    end

    it 'should show an error if the file structure is invalid' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'bulk_users_invalid_structure.csv'), 'text/csv')
      post :import, :csv => file
      flash[:error].should == 'Invalid CSV headers, please refer to the template file.'
    end

    it 'should show an error if the file content is invalid' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'bulk_users_invalid_content.csv'), 'text/csv')
      post :import, :csv => file
      flash[:error].should == 'Invalid CSV content.'
    end

    it 'should show an error if the file has "NULL" values rather than empty cells' do
      file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'bulk_users_with_null_strings.csv'), 'text/csv')
      post :import, :csv => file
      flash[:error].should == 'CSV cannot contain NULL strings. Fields must be blank.'
    end
  end
end
