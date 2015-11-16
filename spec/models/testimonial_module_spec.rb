require 'spec_helper'

describe TestimonialModule do

  context "after_initialize" do
    it "should set default values" do
      expect(subject.number_of_comments).to eq(10)
      expect(subject.comments_order).to eq('social')
    end
  end

  describe "#record_action" do
    before(:each) do
      @user = create(:user, :email => "user@gmail.com")
      new_page = create(:page_with_parent)
      @page = Page.find(new_page.id)
      @email = create(:email)
      @testimonial = create(:testimonial_module)
      ContentModuleLink.create!(:page => @page, :content_module => @testimonial, :layout_container => :sidebar)

      @params = {
          :page_id => @page.friendly_id,
          :module_id => @testimonial.id,
          :facebook_id => 1234,
          :first_name => 'Bruce',
          :last_name => 'Wayne',
          :email => 'bruce@example.com',
          :suburb => 'Sydney'
      }
      @options = {facebook_id: 123, testimonial_text: 'testimonial text' * 200, app_id: 321}
    end

    it "should record the facebook user, testimonial and user activity event" do
      @testimonial.record_action(@user, @page, @email, @params, @options)

      user = User.find_by_email('user@gmail.com')
      expect(FacebookUser.where(user_id: user.id, facebook_id: 123, app_id: 321).count).to eq(1)
      expect(Testimonial.where(user_id: user.id, testimonial_text: @options[:testimonial_text]).count).to eq(1)
      expect(UserActivityEvent.where(user_id: user.id, page_id: @page.id, content_module_id: @testimonial.id).count).to eq(1)
    end

  end
end
