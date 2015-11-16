require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::GetTogethersController do
  before(:each) do
    sign_in create(:admin_user)
  end

  describe "responding to 'GET' new" do
    it "should " do
      campaign = create(:campaign)
      get :new, :campaign_id => campaign.id

      assigns(:get_together).should_not be_nil
      assigns(:get_together).content_module.should_not be_nil
      assigns(:get_together).content_module.should be_a_kind_of(HtmlModule)
    end
  end

  describe "responding to GET show" do
    it "should return a list of events" do
      get_together = create(:get_together)
      event = create(:event, :get_together => get_together)

      get :show, :id => get_together.id

      assigns(:events).should include(event)
    end

    it "should display paginated search results if a query is specified" do
      query = "abcd"
      time = Time.local(2013,8,1,12,0,0)
      Timecop.freeze(time)
      get_together = create(:get_together)
      first_event = create(:event, :name => query, :get_together => get_together)
      Timecop.travel(time + 1.day)
      second_event = create(:event, :name => query, :get_together => get_together)
      Timecop.return

      expected_events = [second_event, first_event]
      get :show, :id => get_together.id, :query => query
      assigns(:events).should == expected_events
    end

    context "with query" do

      before :each do
        @get_together = create(:get_together, from_date: 1.year.ago.to_date)
        create(:event, get_together: @get_together, name: 'Find me by name') # unconfirmed
        create(:cancelled_event, get_together: @get_together)
        create(:confirmed_event, get_together: @get_together, capacity: 0) # full
        create(:confirmed_event, get_together: @get_together, postcode: '2515') # open
        Timecop.travel(2.weeks.ago) { create(:confirmed_event, get_together: @get_together) } # ended
      end

      %w(unconfirmed canceled full open ended).each do |s|
        it "should search by status #{s}" do
          get :show, :id => @get_together.id, :query => s
          assigns(:events).size.should == 1
          assigns(:events)[0].status.should == s
        end
      end

      it "should search by name case insensitive" do
        get :show, :id => @get_together.id, :query => 'find ME by name'
        assigns(:events).all.size.should == 1
        assigns(:events)[0].name.should == 'Find me by name'
      end

      it "should search by postcode" do
        get :show, :id => @get_together.id, :query => '2515'
        assigns(:events).all.size.should == 1
        assigns(:events)[0].postcode.should == '2515'
      end
    end
  end
end
