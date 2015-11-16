require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ScorecardsController do

  describe "#index" do
    render_views
    context 'from a location' do
      before do
        @postcode_nsw = create(:postcode, state: 'NSW')
        @postcode_act = create(:postcode, state: 'ACT')
        @polling_booth_nsw = create(:polling_booth, postcode: @postcode_nsw, electorate: create(:electorate), latitude: 10, longitude: 50)
        @polling_booth_act = create(:polling_booth, postcode: @postcode_act, electorate: create(:sydney_federal), latitude: 100, longitude: 500)
      end

      it 'returns the scorecard for the state of the closest polling booths' do
        get :index, latlng: "9,40"
        response.should render_template(partial: '_nsw_scorecard')

        get :index, latlng: '99, 400'
        response.should render_template(partial: '_act_scorecard')
      end
    end

    context 'no location provided' do
      it "returns the Nationwide scorecard when location is nil" do
        polling_booth_indi = create(
          :polling_booth,
          postcode: create(:postcode, state: "TAS"),
          electorate: create(:electorate, name: "An electorate"),
          latitude: 20,
          longitude: 30)

        get :index
        response.should render_template(partial: '_nationwide_scorecard')
      end
    end
  end
end
