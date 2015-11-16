require 'spec_helper'

describe TestimonialController do
  describe ".record_action" do
    before(:each) do
      @user = create(:user)
      email = create(:email)
      @testimonial_module = create(:testimonial_module)
      token = EmailTrackingToken.encode(@user.id, email.id)
      @page = create(:page_with_parent)
      
      @params = {page_id: @page.id, module_id: @testimonial_module.id, facebook_id: 123, testimonial_text: 'testimonial text', app_id: 321, t: token}
      cookies.permanent.signed[:user_id] = @user.id
    end

    context 'valid request' do
      it "should record the action" do
        post :record_action, @params
        expect(UserActivityEvent.where(user_id: @user.id, content_module_id: @testimonial_module.id, page_id: @page.id).count).to eq(1)
      end

      it "should respond with success for a valid post" do
        post :record_action, @params
        expect(response.status).to eq(200)
      end
    end

    context "invalid parameters" do
      it "should raise an exception when the page cannot be found" do
        @params[:page_id] = -1
        expect { post(:record_action, @params) }.to raise_error(Exception, /Couldn't find Page with 'id'=-1/)
      end

      it "should raise an exception when the ask cannot be found" do
        @params[:module_id] = -1
        expect { post(:record_action, @params) }.to raise_error(Exception, /Couldn't find ContentModule with 'id'=-1/)
      end

      it "should raise an exception when the user cannot be found" do
        cookies.permanent.signed[:user_id] = -1
        expect { post(:record_action, @params) }.to raise_error(Exception, /Couldn't find User with 'id'=-1/)
      end
    end
  end
end
