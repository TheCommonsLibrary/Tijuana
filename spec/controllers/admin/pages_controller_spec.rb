require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::PagesController do
  include Devise::TestHelpers # to give your spec access to helpers

  before(:each) do
    @page = create(:page_with_parent)
    sign_in create(:admin_user)
  end

  describe "responding to GET add_content_module" do
    it "should create an HTML module at the end of the page" do
      3.times do
        ContentModuleLink.create!(:page => @page, :content_module => create(:html_module), :layout_container => "main_content")
      end
      get :add_content_module, :id => @page.id, :type => "HtmlModule", :container => "main_content", format: 'js'
      page = Page.find(@page.id)
      page.should have(4).main_content_modules
      page.content_modules.last.should be_an_instance_of HtmlModule
    end

    it "should create a petition module and save without validations" do
      get :add_content_module, :id => @page.id, :type => "PetitionModule", :container => "sidebar", format: 'js'
      page = Page.find(@page.id)
      page.should have(1).sidebar_content_modules
      page.content_modules.last.should be_an_instance_of PetitionModule
    end
  end

  describe "responding to PUT sort" do
    it "should reorder content modules even if validation fails" do
      html = ContentModuleLink.create!(:page => @page, :content_module => create(:html_module), :layout_container => "main_content")
      invalid_petition = PetitionModule.new
      invalid_petition.save(:validate => false)
      petition = ContentModuleLink.create!(:page => @page, :content_module => invalid_petition, :layout_container => "main_content")
      petition.content_module.should_not be_valid

      html.position.should == 1
      petition.position.should == 2

      put :sort_content_modules, :campaign_id => @page.page_sequence.campaign_id, :page_sequence_id => @page.page_sequence_id, :id => @page.id, :content_module => [petition.content_module.id.to_s, html.content_module.id.to_s]
      html.reload.position.should == 2
      petition.reload.position.should == 1
    end
  end

  describe "manipulating content modules" do
    before :each do
      @page = create(:page_with_parent)
      @m1 = ContentModuleLink.create!(:page => @page, :content_module => HtmlModule.create!, :position => 1, :layout_container => "main_content")
      @m2 = ContentModuleLink.create!(:page => @page, :content_module => HtmlModule.create!, :position => 2, :layout_container => "main_content")
      @m3 = ContentModuleLink.create!(:page => @page, :content_module => HtmlModule.create!, :position => 3, :layout_container => "main_content")
      @m4 = ContentModuleLink.create!(:page => @page, :content_module => HtmlModule.create!, :position => 4, :layout_container => "main_content")
      @m5 = ContentModuleLink.create!(:page => @page, :content_module => HtmlModule.create!, :position => 5, :layout_container => "main_content")
      @m6 = ContentModuleLink.create!(:page => @page, :content_module => HtmlModule.create!, :position => 6, :layout_container => "main_content")
    end

    it "should remove a content module" do
      id = @m3.content_module.id
      get :remove_content_module, :id => @page.id, :content_module_id => id
      @page.content_modules.count.should == 5
      @page.content_modules.any? { |m| m.id == id }.should be false
    end

    it "should set the position of each of the modules after ordering" do
      put :sort_content_modules, :page_sequence_id => @page.page_sequence_id, :id => @page.id, :content_module => [@m2.content_module.id.to_s, @m4.content_module.id.to_s, @m1.content_module.id.to_s, @m6.content_module.id.to_s, @m5.content_module.id.to_s, @m3.content_module.id.to_s]
      @m1.reload.position.should == 3
      @m2.reload.position.should == 1
      @m3.reload.position.should == 6
      @m4.reload.position.should == 2
      @m5.reload.position.should == 5
      @m6.reload.position.should == 4
    end

    it "should programmatically switch the layout container of the module and move it to the bottom of the list" do
      @m1.layout_container = :sidebar
      @m1.save

      @m1.reload.layout_container.should == :sidebar
      @m1.position.should == 1

      put :switch_container, :page_sequence_id => @page.page_sequence_id, :id => @page.id, :content_module_id => @m1.content_module.id
      @m1.reload.layout_container.should == :main_content
      @m1.position.should == 6
    end
  end

  describe "bookmarking" do
    before :each do
      @page = create(:page_with_parent)
      @cm = create(:html_module)
    end

    it "should bookmark a content module" do
      xhr :get, :bookmark_content_module, :id => @page.id, :content_module_id => @cm.id, :bookmark_name => "Bookmark One"
      response.should be_success
      ContentModule.find(@cm.id).should be_bookmarked
    end

    it "should unbookmark a content module" do
      BookmarkedContentModule.create!(:content_module_id => @cm.id, :name => "Bookmarked")
      ContentModule.find(@cm.id).should be_bookmarked

      xhr :get, :unbookmark_content_module, :id => @page.id, :content_module_id => @cm.id
      response.should be_success
      ContentModule.find(@cm.id).should_not be_bookmarked
    end
  end

  describe "responding to GET add_from_bookmarks" do
    it "should link a module from bookmarks at the bottom of the page" do
      3.times do
        ContentModuleLink.create!(:page => @page, :content_module => create(:html_module), :layout_container => "sidebar")
      end
      bookmark = BookmarkedContentModule.create!(:content_module => create(:html_module), :name => "Useful Widget")
      get :add_from_bookmarks, :id => @page.id, :content_module_id => bookmark.content_module.id, :container => "sidebar", format: 'js'

      page = Page.find(@page.id)
      page.should have(4).sidebar_content_modules
      page.content_modules.last.id.should == bookmark.content_module.id
    end
  end

  describe "responding to GET unlink_content_module" do
    it "should unlink a module and replace it with a clone" do
      first_page = create(:page_with_parent)
      second_page = create(:page_with_parent)
      petition = create(:petition_module, :signatures_target => 1111)
      first_link = ContentModuleLink.create!(:page => first_page, :content_module => petition, :layout_container => "sidebar")

      second_page.content_module_links.create!(:content_module => create(:html_module), :layout_container => "sidebar")
      broken_link = second_page.content_module_links.create!(:page => second_page, :content_module => petition, :layout_container => "sidebar")
      second_page.content_module_links.create!(:page => second_page, :content_module => create(:html_module), :layout_container => "sidebar")
      broken_link.position.should == 2

      get :unlink_content_module, :id => second_page.id, :content_module_id => petition.id, format: 'js'

      second_page.reload
      second_page.should have(3).content_module_links
      broken_link.reload
      broken_link.layout_container.should == :sidebar
      broken_link.position.should == 2
      broken_link.content_module.signatures_target.should == 1111
      broken_link.content_module.id.should_not == petition.id

      first_page.reload
      first_page.should have(1).content_module_links
      first_page.content_modules.first.id.should == petition.id
    end
  end

  describe "responding to PUT update" do
    before(:each) do
      @page_sequence = create(:page_sequence_with_parent)
      @petition_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:petition_module), :layout_container => "sidebar")
    end

    describe "with valid params" do
      it "should update the admin page  and its content modules and redirect to its admin page sequence page" do
        content_module_params = { @petition_module_link.content_module.id.to_s=>{:id=>@petition_module_link.content_module.id, :content => "This is petition content"}}

        put :update, :campaign_id => @page.page_sequence.campaign_id,
            :page_sequence_id => @page_sequence.id,
            :id => @page.id, :content_modules => content_module_params,
            :page => {}

        @petition_module_link.reload.content_module.content.should == "This is petition content"
        response.should redirect_to(admin_page_sequence_path(@page_sequence))
        response.status.should == 302
      end

      it "should invoke appropriate validators when save and validate is called" do
        html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:html_module), :layout_container => "main_content")
        direct_landing_html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:direct_landing_html_module), :layout_container => "header_content")
        HtmlValidator.stub(:service_available?).and_return(false)
        HtmlValidator.should_receive(:validate_each).with(html_module_link.content_module, :content, "<p>this is the test module</p>")
        HtmlValidator.should_receive(:validate_each).with(direct_landing_html_module_link.content_module, :content, "<p>this is the direct landing test module</p>")
        HtmlValidator.should_not_receive(:validate_each).with(@petition_module_link.content_module, :content, @petition_module_link.content_module.content)
        LinksLiveValidator.should_receive(:validate_each).with(@page, :thankyou_email_text, "Some email text")

        content_module_params = { @petition_module_link.content_module.id.to_s=>{:id=>@petition_module_link.content_module.id, :content => @petition_module_link.content_module.content},
                                  html_module_link.content_module.id.to_s => { :id => html_module_link.content_module.id, :content => "<p>this is the test module</p>"},
                                  direct_landing_html_module_link.content_module.id.to_s => { :id => direct_landing_html_module_link.content_module.id, :content => "<p>this is the direct landing test module</p>"}}

        put :update, :submit => 'Save & Validate',
            :campaign_id => @page.page_sequence.campaign_id,
            :page_sequence_id => @page_sequence.id, :id => @page.id,
            :content_modules => content_module_params, :page => { :thankyou_email_text => "Some email text" }
      end

      it "should not invoke validators when save (without validate) is called" do
        content_module_params = { @petition_module_link.content_module.id.to_s=>{:id=>@petition_module_link.content_module.id, :content => "This is petition content"}}
        html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:html_module), :layout_container => "main_content")
        direct_landing_html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:direct_landing_html_module), :layout_container => "header_content")

        HtmlValidator.should_not_receive(:validate_each).with(html_module_link.content_module, :content, html_module_link.content_module.content)
        HtmlValidator.should_not_receive(:validate_each).with(direct_landing_html_module_link.content_module, :content, direct_landing_html_module_link.content_module.content)

        put :update, :submit => 'Save', :campaign_id => @page.page_sequence.campaign_id, :page_sequence_id => @page_sequence.id, :id => @page.id,
            :content_modules => content_module_params, page: {}

      end

      it "should save when save and validate is called" do
        content_module_params = { @petition_module_link.content_module.id.to_s=>{:id=>@petition_module_link.content_module.id, :content => "This is petition content"}}
        put :update, :submit => 'Save & Validate',
            :campaign_id => @page.page_sequence.campaign_id,
            :content_modules => content_module_params,
            :page_sequence_id => @page_sequence.id, :id => @page.id, :page => { :name => "New page" }
        found_page = Page.find(@page.id)
        found_page.name.should == "New page"
      end
    end

    describe 'without params' do
      it 'should update the admin page  and its content modules and redirect to its admin page sequence page' do
        put :update, :campaign_id => @page.page_sequence.campaign_id,
            :page_sequence_id => @page_sequence.id,
            :id => @page.id, page: {}
        response.should redirect_to(admin_page_sequence_path(@page_sequence))
        response.status.should == 302
      end

      it "should invoke appropriate validators when save and validate is called" do
        html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:html_module), :layout_container => "main_content")
        direct_landing_html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:direct_landing_html_module), :layout_container => "header_content")
        HtmlValidator.stub(:service_available?).and_return(false)
        HtmlValidator.should_receive(:validate_each).with(html_module_link.content_module, :content, html_module_link.content_module.content)
        HtmlValidator.should_receive(:validate_each).with(direct_landing_html_module_link.content_module, :content, direct_landing_html_module_link.content_module.content)
        HtmlValidator.should_not_receive(:validate_each).with(@petition_module_link.content_module, :content, @petition_module_link.content_module.content)
        LinksLiveValidator.should_receive(:validate_each).with(@page, :thankyou_email_text, "Some email text")

        put :update, :submit => 'Save & Validate',
            :campaign_id => @page.page_sequence.campaign_id,
            :page_sequence_id => @page_sequence.id, :id => @page.id,
            :page => { :thankyou_email_text => "Some email text" }
      end

      it 'should not invoke validators when save (without validate) is called' do
        html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:html_module), :layout_container => "main_content")
        direct_landing_html_module_link = ContentModuleLink.create!(:page => @page, :content_module => create(:direct_landing_html_module), :layout_container => "header_content")

        HtmlValidator.should_not_receive(:validate_each).with(html_module_link.content_module, :content, html_module_link.content_module.content)
        HtmlValidator.should_not_receive(:validate_each).with(direct_landing_html_module_link.content_module, :content, direct_landing_html_module_link.content_module.content)

        put :update, :submit => 'Save', :campaign_id => @page.page_sequence.campaign_id, :page_sequence_id => @page_sequence.id, :id => @page.id, page: {}
      end

      it 'should save when save and validate is called' do
        put :update, :submit => 'Save & Validate',
            :campaign_id => @page.page_sequence.campaign_id,
            :page_sequence_id => @page_sequence.id, :id => @page.id, :page => { :name => "New page" }
        found_page = Page.find(@page.id)
        found_page.name.should == "New page"
      end
    end

    describe "with invalid params" do
      it "should not save the admin page and re-render the form" do
        invalid_petition = PetitionModule.new
        invalid_petition.save(:validate => false)
        petition = ContentModuleLink.create!(:page => @page, :content_module => invalid_petition, :layout_container => "main_content")
        petition.content_module.should_not be_valid
        content_module_params = { @petition_module_link.content_module.id.to_s=>{:id=>@petition_module_link.content_module.id, :content => petition.content_module.id.to_s}}

        put :update, :campaign_id => @page.page_sequence.campaign_id, :page_sequence_id => @page_sequence.id, :id => @page.id, :content_modules => content_module_params, page: {}

        response.should_not redirect_to(admin_page_sequence_path(@page_sequence))
        response.should render_template("edit")
        flash[:error].should eql("Your changes have NOT BEEN SAVED YET. Please see the errors below.")

      end
    end
  end

  describe "#add_tag" do
    it "should add tag to the given page" do
      page = create(:page_with_parent)

      post :add_tag, id: page.id, tag: "tag1"
      page.reload

      page.tag_list.count.should == 1
      page.tag_list.should include("tag1")
    end
  end

  describe "#delete_tag" do
    it "should delete tag from the given page" do
      page = create(:page_with_parent)
      page.tag_list.add("tag1", "tag2")
      page.save

      post :remove_tag, id: page.id, tag: "tag1"
      page.reload

      page.tag_list.count.should == 1
      page.tag_list.should_not include("tag1")
      page.tag_list.should include("tag2")
    end
  end
end
