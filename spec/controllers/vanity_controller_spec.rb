require 'spec_helper'

describe VanityController do
  include VanityTestHelper

  describe '#add_participant' do
    context 'with no token' do
      before { new_ab_test :price_options }
      before { post :add_participant, v: "price_options" }

      specify{ response.should be_success }
    end

    context 'with no matching experiment' do
      before do
        post :add_participant, v: "no_matching_experiment"
      end

      specify{ expect(response.code).to eq('404') }
    end

    context 'with a token' do
      let(:user) { create(:user) }
      let!(:tracking_token) { EmailTrackingToken.encode(user.id, 0) }
      before { new_ab_test :price_options }
      before { post :add_participant, v: "price_options", t: tracking_token }

      specify{ response.should be_success }
      it 'should store the user_id against the participant' do
        vanity_participant_model.where(user_id: user.id).count.should == 1
      end
    end
  end

  describe '#index' do
    include Devise::TestHelpers

    context 'with unauthenticated user' do
      it 'should redirect them to login' do
        get :index
        response.should be_redirect
      end
    end

    context 'with admin user' do
      it "should allow admin users to access the vanity dashboard" do
        sign_in create(:admin_user)
        get :index
        response.should be_success
      end
    end
  end
end
