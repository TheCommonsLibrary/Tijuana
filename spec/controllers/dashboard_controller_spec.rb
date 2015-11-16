require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe DashboardController do

  before :each do
    @user = create(:user, :is_admin => false)
    sign_in @user
  end

  describe "managing users campaign involvement" do
    it "should should show all the campaigns " do
      campaigns = [create(:campaign), create(:campaign)]

      Campaign.should_receive(:find_all_by_opt_out).with(true).and_return(campaigns)

      controller.stub(:current_user) { @user }

      get :index
    end
  end

  #render_views
  describe "User Dashboard" do
    before :each do
      @recurring_donations = [create(:recurring_donation, :user => @user),create(:recurring_donation, :user => @user)]
    end
    
    after :each do
      Timecop.return
    end

    it "should populate user's donation" do
      get :index

      assigns(:recurring_donations).should include @recurring_donations[0]
      assigns(:recurring_donations).should include @recurring_donations[1]
      response.should be_success
    end

    it "should load only last month's transactions by default'" do
      transactions = [Transaction.create!(:donation => @recurring_donations[0], :successful => true),
                      Transaction.create!(:donation => @recurring_donations[0], :successful => true),
                      Transaction.create!(:donation => @recurring_donations[0], :successful => true, :created_at => 2.months.ago)]
      get :index

      assigns(:transactions).respond_to?(:total_pages).should be true
      assigns(:transactions).should include transactions[0]
      assigns(:transactions).should include transactions[1]
      assigns(:transactions).should_not include transactions[2]
      assigns(:from_date).should_not be_nil
      assigns(:to_date).should_not be_nil
      response.should be_success
    end

    def create_hosted_and_attendee_events(date, get_together)
      {:hosted => create(:event, date: date, host: @user, get_together: get_together), :attending => create(:event, date: date, attendees: [@user], get_together: get_together)}
    end

    it "should only load attended events from up to one month ago" do
      Timecop.freeze('2010-03-31') #create dates in the 'future' first
      get_together = create(:get_together, from_date: Date.new(2000, 1, 1), to_date: Date.new(2020, 1, 1))
      really_old_event = create_hosted_and_attendee_events(Date.new(2012, 1, 1), get_together)
      less_than_a_month_ago = create_hosted_and_attendee_events(Date.new(2013, 3, 1), get_together)
      in_the_future = create_hosted_and_attendee_events(Date.new(2013, 4, 1), get_together)

      Timecop.freeze('2013-03-31')
      get :index

      assigns(:events)[:as_attendee].should include(less_than_a_month_ago[:attending], in_the_future[:attending])
      assigns(:events)[:as_attendee].length.should == 2
      Timecop.return
    end

    it "should only load hosted events from up to three months ago" do
      Timecop.freeze('2010-03-31') #create dates in the 'future' first
      get_together = create(:get_together, from_date: Date.new(2000, 1, 1), to_date: Date.new(2020, 1, 1))
      really_old_event = create_hosted_and_attendee_events(Date.new(2012, 1, 1), get_together)
      three_months_ago = create_hosted_and_attendee_events(Date.new(2013, 1, 1), get_together)
      three_months_and_a_day_ago = create_hosted_and_attendee_events(Date.new(2012, 12, 30), get_together)
      in_the_future = create_hosted_and_attendee_events(Date.new(2013, 4, 1), get_together)

      Timecop.freeze('2013-03-31')
      get :index

      assigns(:events)[:as_host].should include(three_months_ago[:hosted], in_the_future[:hosted])
      assigns(:events)[:as_host].length.should == 2
      Timecop.return
    end
  end

  describe "Donation history" do
    before(:each) do
      donation = create(:donation, :user => @user)
      @transactions = [Transaction.create!(:donation => donation, :successful => true, :created_at => Time.now),
                       Transaction.create!(:donation => donation, :successful => true, :created_at => Date.tomorrow),
                       Transaction.create!(:donation => donation, :successful => true, :created_at => 3.days.from_now),
                       Transaction.create!(:donation => donation, :successful => true, :created_at => 1.month.ago),
                       Transaction.create!(:donation => donation, :successful => true, :created_at => 2.months.ago)]
    end

    it "should filter donations by date'" do
      two_days_ago = 2.days.ago.strftime("%d-%m-%Y")
      two_days_from_now = 2.days.from_now.strftime("%d-%m-%Y")
      get :donation_history, :from => two_days_ago, :to => two_days_from_now

      response.should be_success
      assigns(:transactions).size.should eql 2
      assigns(:transactions).should include @transactions[0]
      assigns(:transactions).should include @transactions[1]
      assigns(:from_date).should_not be_nil
      assigns(:to_date).should_not be_nil
    end

    it "should show bad request if search date is in wrong format dd-mm-yyyy" do
      from_date = "23-44-2012"
      to_date = "11-11-2012"
      get :donation_history, :from => from_date, :to => to_date

      response.status.should == 400
      response.headers["Content"].should =~ /date in format dd-mm-yyyy/
    end

    it "should respond to js requests" do
      two_days_ago = 2.days.ago.strftime("%d-%m-%Y")
      two_days_from_now = 2.days.from_now.strftime("%d-%m-%Y")
      xhr :get, :donation_history, :from => two_days_ago, :to => two_days_from_now, :format => "js"

      response.should be_success
      (response.headers['Content-Type'] =~ /javascript/).should_not be_nil
    end
  end

  describe "Cancel event attendance" do
    it "cancels an attendee's attendance and redirects to the dashboard event page with a notice current user is host" do
      event = create(:event, host: @user)
      attendee = create(:user)
      Event.any_instance.should_receive(:cancel_attendance!).with(attendee, nil).and_return(true)
      post :cancel_event_attendee, :id => event.id, user: {email: attendee.email}
      response.should redirect_to("#{dashboard_path}#events")
      flash[:notice].should_not be_nil
    end

    it "redirects to the dashboard event page with an error current user is not host of event" do
      event = create(:event)
      attendee = create(:user)
      Event.any_instance.should_not_receive(:cancel_attendance!)
      post :cancel_event_attendee, :id => event.id, user: {email: attendee.email}
      response.should redirect_to("#{dashboard_path}#events")
      flash[:error].should_not be_nil
    end

    it "cancels the current user's attendance and redirect to the dashboard event page with a notice" do
      event = create(:event)
      event.add_attendee!(@user)
      Event.any_instance.should_receive(:cancel_attendance!).with(@user, nil).and_return(true)
      post :cancel_event_attendee, :id => event.id
      response.should redirect_to("#{dashboard_path}#events")
      flash[:notice].should_not be_nil
    end

    it "redirects to the dashboard event page with an error if cancelling fails" do
      event = create(:event)
      event.add_attendee!(@user)
      Event.any_instance.should_receive(:cancel_attendance!).with(@user, nil).and_return(false)
      post :cancel_event_attendee, :id => event.id
      response.should redirect_to("#{dashboard_path}#events")
      flash[:error].should_not be_nil
    end
  end

  describe "Update credit card" do
    before :each do
      @recurring_donation = create(:recurring_donation, :user => create(:user))
    end

    it "should be able to get update card page" do
      @recurring_donation.stub(:can_update_anonymously?).and_return(true)
      Donation.stub(find: @recurring_donation)
      post :update_card, :id => @recurring_donation.id

      response.should be_success
    end

    it "should not be able to get update card page" do
      @recurring_donation.stub(:can_update_anonymously?).and_return(false)
      Donation.stub(find: @recurring_donation)
      post :update_card, :id => @recurring_donation.id

      response.should_not be_success
    end
  end
end

