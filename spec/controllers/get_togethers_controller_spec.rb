require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe GetTogethersController do
  before :each do
    @an_instant = Time.now

    @get_togethers = [
      create(:get_together, :to_date => @an_instant+1.days),
      create(:get_together, :to_date => @an_instant-3.days),
      create(:get_together, :to_date => @an_instant+3.days)
    ]
  end

  describe "theming" do
    it "should fall back to app theme by default" do
      get_together = create(:get_together)
      get :show, :id => get_together[:id]
      response.should render_template(:layout => 'layouts/application')
    end

    it "should render custom theme" do
      get_together = create(:get_together)
      get_together.theme = Theme.create(:name=>'no_branding', :display_name=>'No Brand')
      get_together.save!
      get :show, :id => get_together[:id]
      response.should render_template(:layout => 'layouts/themes/no_branding')
    end
  end

  describe "GET #index" do
    it "should return a date ordered list of Get Togethers occurring today or in the future" do
      current_get_togethers = @get_togethers.reject { |get_together| get_together[:to_date] < @an_instant }
      get :index
      assigns(:current_get_togethers).should == current_get_togethers
    end

    it "should return a date ordered list of Get Togethers older than today" do
      past_get_togethers = @get_togethers.reject { |get_together| get_together[:to_date] >= @an_instant }
      get :index
      assigns(:past_get_togethers).should == past_get_togethers
    end

  end

  describe "#GET show" do
    it "should return an individual Get Together" do
      get_together = create(:get_together)
      get :show, :id => get_together[:id]
      assigns(:get_together).should == get_together
    end

    context 'json' do

      context 'when searching' do
        it "should load postcode if valid" do
          get_together = create(:get_together)
          postcode = create(:postcode, :number=>'2073')
          get :show, :id => get_together[:id], :origin_postcode=>'2073', format: 'json'
          assigns[:search_origin].should == postcode
        end

        it "should have nil postcode if invalid" do
          get_together = create(:get_together)
          get :show, :id => get_together[:id], :origin_postcode=>'blah', format: 'json'
          assigns[:search_origin].should be_nil
        end

        it "should set search origin from latitude and longitude" do
          get_together = create(:get_together)
          get :show, :id => get_together[:id], :latitude=>'37.792', :longitude=>'-122.393', format: 'json'
          assigns[:search_origin].should == [37.792,-122.393]
        end

        it "should set search radius if supplied" do
          get_together = create(:get_together)
          get :show, :id => get_together[:id], :search_radius => 15, format: 'json'
          assigns[:search_radius].should == 15
        end

        it "should set search radius the default one set by an admin if not supplied" do
          get_together = create(:get_together, search_radius: 50)
          get :show, :id => get_together[:id], :latitude=>'37.792', :longitude=>'-122.393', format: 'json'
          assigns[:search_radius].should == 50
        end

        context 'ordering' do

          context 'normal get togethers' do
            it 'for normal get together, orders results by distance ascending' do
              get_together = create(:get_together)
              event_close = create(:confirmed_event, get_together: get_together, address_latitude: '38', address_longitude: '-122.80')
              event_far = create(:confirmed_event, get_together: get_together, address_latitude: '38', address_longitude: '-123')
              get :show, :id => get_together[:id], format: 'json', :latitude=>'38', :longitude=>'-122.60'
              assigns[:events].should == [event_close, event_far]
            end

            it 'limits the number of results if specified' do
              get_together = create(:get_together)
              create(:confirmed_event, get_together: get_together, address_latitude: '38', address_longitude: '-122')
              create(:confirmed_event, get_together: get_together, address_latitude: '38', address_longitude: '-122')
              get :show, :id => get_together[:id], format: 'json', :latitude=>'38', :longitude=>'-122', :limit => 1
              assigns[:events].length.should == 1
            end
          end

          context 'admin get togethers' do
            it 'for admin managed get together, first orders by capacity remaining descending, then by distance descending' do
              get_together = create(:get_together, is_admin_managed: true, search_radius: 150)
              event_popular_big = create(:confirmed_event, get_together: get_together, capacity: 10, address_latitude: '38', address_longitude: '-122')
              event_popular_big.add_attendee!(create(:user))
              event_popular_big.add_attendee!(create(:user))

              event_popular_small = create(:confirmed_event, get_together: get_together, capacity: 5, address_latitude: '38', address_longitude: '-122')
              event_popular_small.add_attendee!(create(:user))
              event_popular_small.add_attendee!(create(:user))

              event_unpopular_close = create(:confirmed_event, get_together: get_together, capacity: 10, address_latitude: '38', address_longitude: '-122')
              event_unpopular_close.add_attendee!(create(:user))

              event_unpopular_far = create(:confirmed_event, get_together: get_together, capacity: 10, address_latitude: '38', address_longitude: '-123')
              event_unpopular_far.add_attendee!(create(:user))

              get :show, :id => get_together[:id], format: 'json', :latitude=>'38', :longitude=>'-122'
              assigns[:events].should == [event_unpopular_close, event_unpopular_far, event_popular_big, event_popular_small]
            end

            it 'limits the number of results if specified' do
              get_together = create(:get_together, is_admin_managed: true)
              create(:confirmed_event, get_together: get_together, address_latitude: '38', address_longitude: '-122')
              create(:confirmed_event, get_together: get_together, address_latitude: '38', address_longitude: '-122')
              get :show, :id => get_together[:id], format: 'json', :latitude=>'38', :longitude=>'-122', :limit => 1
              assigns[:events].length.should == 1
            end
          end

        end


      end

      it "should return all confirmed events if no search parameters supplied" do
        get_together = create(:get_together)
        event1 = create(:confirmed_event, get_together: get_together)
        event2 = create(:confirmed_event, get_together: get_together)
        non_confirmed_event = create(:event, get_together: get_together)
        get :show, :id => get_together[:id], format: 'json'
        assigns[:events].length.should == 2
        assigns[:events].should include event1
        assigns[:events].should include event2
        assigns[:events].should_not include non_confirmed_event
      end

      it "should return no results if too many results returned" do
        original_max_number_of_nationwide_search_results = GetTogethersController::MAX_NUMBER_OF_NATIONWIDE_RESULTS
        Kernel::silence_warnings do GetTogethersController::MAX_NUMBER_OF_NATIONWIDE_RESULTS = 1 end
        begin
          get_together = create(:get_together)
          event1 = create(:confirmed_event, get_together: get_together)
          event2 = create(:confirmed_event, get_together: get_together)
          get :show, :id => get_together[:id], format: 'json'
          assigns[:events].length.should == 0
        ensure
          Kernel::silence_warnings do GetTogethersController::MAX_NUMBER_OF_NATIONWIDE_RESULTS = original_max_number_of_nationwide_search_results end
        end
      end

      context "with managed get together" do

        before :each do
          @far_postcode = create(:postcode_for_darwin)
          @managed_get_together = create(:get_together, :is_admin_managed => true)
          @managed_event = create(:confirmed_event, get_together: @managed_get_together, address_latitude: @far_postcode.latitude, address_longitude: @far_postcode.longitude)

          @postcode = create(:postcode)
          @community_get_together = create(:get_together, managed_get_together: @managed_get_together)
          @community_event = create(:confirmed_event, get_together: @community_get_together, address_latitude: @postcode.latitude, address_longitude: @postcode.longitude)
        end

        it "returns only managed events if there are any within search radius" do
          get :show, :id => @community_get_together[:id], format: 'json', :origin_postcode => @postcode.number, :search_radius => '10000'
          assigns[:events].should == [@managed_event]
        end

        it "returns community events if there are any no managed events within search radius" do
          get :show, :id => @community_get_together[:id], format: 'json', :origin_postcode => @postcode.number, :search_radius => '10'
          assigns[:events].should == [@community_event]
        end

        it "returns mangaged and community events when called without location" do
          get :show, :id => @community_get_together[:id], format: 'json'
          assigns[:events].should include(@managed_event)
          assigns[:events].should include(@community_event)
        end
      end

    end

    it "should return 404 when requesting an unknown id" do
      get :show, :id => "i-am-a-made-up-id"
      response.code.should == "404"
    end
  end
end
