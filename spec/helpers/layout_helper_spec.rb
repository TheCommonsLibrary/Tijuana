require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe "layout helper" do

  describe "#title" do
    it "should set title as raw text" do
      title = "don't let them do this > see here <"
      helper.title(title)
      helper.content_for(:title).should eql title
      helper.show_title?.should be true
    end
  end

  describe "description" do
    it "should use the facebook description of the page sequence" do
      page_sequence = create(:page_sequence, :html_meta_description => "this is the html meta description that should be used in the Facebook share")
      @page = create(:page, :page_sequence => page_sequence)
      tfm = create(:tell_a_friend_module)
      ContentModuleLink.create!(:content_module => tfm, :page => @page, :layout_container => :main_container)

      helper.open_graph_description.should == "this is the html meta description that should be used in the Facebook share"
    end

    it "should use the facebook description of the get together" do
      get_together = create(:get_together, :html_meta_description => "this is the html meta description that should be used in the Facebook share")
      @event = create(:event, :get_together => get_together)

      helper.open_graph_description.should == "this is the html meta description that should be used in the Facebook share"
    end

    it "should use a default description if no page given" do
      helper.open_graph_description.should == "An independent movement to build a progressive Australia and bring participation back into our democracy."
    end

  end

  describe "#share_image_path" do
    it "should return the default image if no page given" do
      helper.stub(:asset_path) do |arg|
        'assets/' + arg
      end
      helper.open_graph_share_image_path.to_s.should match(/#{root_url}assets\/public\/getup_logo.*\.png/)
    end

    it "should return the facebook image set on the page sequence" do
      page_sequence = create(:page_sequence, :facebook_image => "/whatever/module_img.png")
      @page = create(:page, :page_sequence => page_sequence)

      helper.open_graph_share_image_path.should == "/whatever/module_img.png"
    end

    it "should return the facebook image set on the get together" do
      get_together = create(:get_together, :facebook_image => "/whatever/module_img.png")
      @event = create(:event, :get_together => get_together)

      helper.open_graph_share_image_path.should == "/whatever/module_img.png"
    end
  end

  describe "#open_graph_title" do
    it "should return the title of the event" do
      @event = create(:event, :name => "Save the Kittens!")

      helper.open_graph_title.should eql @event.name
    end

    it "should return the title of the landing page in a page_sequence" do
      original = PageSequence.create(:name => "Original Name", :campaign => @campaign, facebook_image: 'http://fb.png')
      first_page = create(:page, :name=>"page1", :page_sequence => original)
      @page = create(:page, :name=>"page2", :page_sequence => original)

      helper.open_graph_title.should eql first_page.name
    end

    it "should return the default page title if page is nil" do

      helper.open_graph_title.should eql "GetUp! Action for Australia"
    end
  end

  describe "#robots_content" do
    context "in production" do
      before { Rails.env.stub(:production? => true) }
      specify {helper.robots_content.should_not match(/noindex/) }
    end

    context "in showcase" do
      before do 
        Rails.env.stub(:production? => false)
        Rails.env.stub(:showcase? => true)
      end
      specify {helper.robots_content.should match(/noindex/) }
    end
  end

end
