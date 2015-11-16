# encoding: utf-8
require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Page do
  context 'with page sequence' do
    before :each do
      @page_sequence = create(:page_sequence_with_parent)
      @first_page = create(:page, :page_sequence => @page_sequence, :name => "page1")
      @last_page = create(:page, :page_sequence => @page_sequence, :name => "page2")
    end

    describe 'next' do
      it "returns next page" do
        @first_page.next.should == @last_page
      end

      it "returns nil if last page" do
        @last_page.next.should be_nil
      end
    end

    describe 'previous' do
      it "returns previous page" do
        @last_page.previous.should == @first_page
      end

      it "returns nil if first page" do
        @first_page.previous.should be_nil
      end
    end

  end

  describe "acts as list" do
    it "should be scoped to the containing page_sequence" do
      page_sequence = create(:page_sequence_with_parent)
      another_page_sequence = create(:page_sequence_with_parent)
      create(:page, :page_sequence => another_page_sequence, :name => "page1")
      create(:page, :page_sequence => another_page_sequence, :name => "page2")
      create(:page, :page_sequence => another_page_sequence, :name => "page3")

      first_page = create(:page, :page_sequence => page_sequence, :name => "page4")
      second_page = create(:page, :page_sequence => page_sequence, :name => "page5")
      first_page.position.should == 1
      second_page.position.should == 2
    end
  end

  describe "validations" do
    before :each do
      @ps = create(:page_sequence_with_parent)
    end

    it "should require a name between 3 and 64 characters" do
      create(:page_with_parent).should be_valid
      Page.new(:name => "Save the kittens!", :page_sequence => @ps).should be_valid
      Page.new(:name => "12", :page_sequence => @ps).should_not be_valid
      Page.new(:name => "X" * 65, :page_sequence => @ps).should_not be_valid
      Page.new(:page_sequence => @ps).should_not be_valid
      Page.new(:name => 'Sally').should_not be_valid
    end

    it "should allow any characters for campaign pages" do
      Page.new(:name => "This really ? would=not work well as a http:// URL", :page_sequence => @ps).should be_valid
    end

    it "should not allow naked links in thankyou email text" do
      page_sequence = create(:page_sequence_with_parent)
      page = build(:page, page_sequence: page_sequence, thankyou_email_text: "With naked link to www.google.com")
      page.should_not be_valid
    end

    it "should not allow whitespace in thankyou email link href attribute" do
      page_sequence = create(:page_sequence_with_parent)
      page = build(:page, page_sequence: page_sequence, thankyou_email_text: "<a href='http://www.google.com   '>afsdffs</a>")
      page.should_not be_valid
    end

    describe "member value override" do
      it "should not allow page to override money type content modules" do
        page = create(:page_with_parent)
        donation_module = create(:donation_module)
        content_module_link = create(:content_module_link, page: page, content_module: donation_module, layout_container: 'sidebar')
        page.should be_valid

        page.member_value_type = 'voice'
        page.should_not be_valid
      end
    end
  end

  describe "thankyou email" do
    it 'substitutes normal quotes for smart quotes' do
      page_sequence = create(:page_sequence_with_parent)
      page = create(:page, page_sequence: page_sequence,
                     thankyou_email_text: '“smart” double and ‘smart’ single quotes',
                     thankyou_email_subject: '“smart” double and ‘smart’ single quotes'
      )

      page.thankyou_email_subject.should == %Q{"smart" double and 'smart' single quotes}
      page.thankyou_email_text.should == %Q{"smart" double and 'smart' single quotes}
    end
  end


  it "knows if it has an ask module" do
    without = create(:page_with_parent)
    without.has_an_ask?.should == false

    with = create(:page_with_parent)
    with.content_modules << create(:petition_module)
    with.has_an_ask?.should == true
  end

  it "knows if it has a donation module" do
    without = create(:page_with_parent)
    without.content_modules << create(:petition_module)
    without.has_a_donation?.should == false

    with = create(:page_with_parent)
    with.content_modules << create(:petition_module)
    with.content_modules << create(:donation_module)
    with.has_a_donation?.should == true
  end

  it "knows if it has a tell a friend module" do
    without = create(:page_with_parent)
    without.content_modules << create(:html_module)
    without.has_tell_a_friend?.should == false

    with = create(:page_with_parent)
    with.content_modules << create(:html_module)
    with.content_modules << create(:tell_a_friend_module)
    with.has_tell_a_friend?.should == true
  end

  it "knows if quick donate is enabled if page contains donation module" do
    without = create(:page_with_parent)
    without.content_modules << create(:donation_module, quick_donate_enabled: false)
    without.quick_donate_enabled?.should == false

    with = create(:page_with_parent)
    with.content_modules << create(:donation_module)
    with.quick_donate_enabled?.should == true
  end

  it "knows if quick donate enabled is false for pages without donation module" do
    without = create(:page_with_parent)
    without.content_modules << create(:html_module)
    without.quick_donate_enabled?.should == false
  end

  describe "required user details" do
    it "should always store values as symbols" do
      page = create(:page_with_parent)
      page.required_user_details = {:first_name => "hidden"}
      page.required_user_details[:first_name].should == :hidden
    end
  end

  describe "user_details_that_are" do
    it "returns names of matching attributes" do
      page = create(:page_with_parent)
      page.required_user_details = {:first_name => "hidden", :last_name => 'required', :mobile_number => :required}
      page.user_details_that_are(:required).should == [:last_name, :mobile_number]
      page.user_details_that_are('required').should == [:last_name, :mobile_number]
    end
  end

  describe "thankyou email" do
    it "should have a default subject" do
      page = create(:page_with_parent, :thankyou_email_subject => nil)
      page.reload
      page.thankyou_email_subject.should == "Thanks for taking action!"
      page.update_attribute(:thankyou_email_subject, "You are excellent.")
      page.thankyou_email_subject.should == "You are excellent."
    end

    it "should have default text" do
      page = create(:page_with_parent, :thankyou_email_text => nil)
      page.reload
      page.thankyou_email_text.should =~ /Dear {NAME|Friend}/
      page.update_attribute(:thankyou_email_text, "Ta very much.")
      page.thankyou_email_text.should == "Ta very much."
    end
  end

  describe "positioning of modules on the page" do
    before :each do
      @page = create(:page_with_parent)

      @m1 = create(:html_module)
      @m2 = create(:html_module)
      @m3 = create(:html_module)
      @m4 = create(:html_module)
      @m5 = create(:html_module)
      @m6 = create(:html_module)
      @m7 = create(:html_module)
      @m8 = create(:html_module)

      ContentModuleLink.create!(:content_module => @m1, :page => @page, :layout_container => :main_content)
      ContentModuleLink.create!(:content_module => @m2, :page => @page, :layout_container => :main_content)
      ContentModuleLink.create!(:content_module => @m3, :page => @page, :layout_container => :sidebar)
      ContentModuleLink.create!(:content_module => @m4, :page => @page, :layout_container => :main_content)
      ContentModuleLink.create!(:content_module => @m5, :page => @page, :layout_container => :sidebar)
      ContentModuleLink.create!(:content_module => @m6, :page => @page, :layout_container => :header_content)
      ContentModuleLink.create!(:content_module => @m7, :page => @page, :layout_container => :header_content)
      ContentModuleLink.create!(:content_module => @m8, :page => @page, :layout_container => :aside_content)
    end

    it "should retrieve the modules in the main content area" do
      page = Page.find(@page.id)
      page.main_content_modules.count.should == 3
      page.main_content_modules.first.should == @m1
      page.main_content_modules.last.should == @m4
    end

    it "should retrieve the modules in the sidebar area" do
      page = Page.find(@page.id)
      page.sidebar_content_modules.count.should == 2
      page.sidebar_content_modules.first.should == @m3
      page.sidebar_content_modules.last.should == @m5
    end

    it "should retrieve the modules in the header area" do
      page = Page.find(@page.id)
      page.header_content_modules.count.should == 2
      page.header_content_modules.first.should == @m6
      page.header_content_modules.last.should == @m7
    end

    it 'should retrieve the modules in the aside area' do
      page = Page.find(@page.id)
      page.aside_content_modules.count.should == 1
      page.aside_content_modules.first.should == @m8
    end

    describe '#reorder_main_content_modules!' do
      context 'Standfirst module' do
        before do
          @standfirst_module = create(:standfirst_module)
          ContentModuleLink.create!(:content_module => @standfirst_module, :page => @page, :layout_container => :main_content)
        end

        it 'should position standfirst module to the first index' do
          page = Page.find(@page.id)
          page.reorder_main_content_modules!.should be true
          page.main_content_modules.first.should == @standfirst_module
          page.main_content_modules.count.should == 4
        end
      end
    end
  end

  it "avoids overwriting view count when receiving high traffic" do
    first_ref = create(:page_with_parent)
    second_ref = Page.find(first_ref.id)
    first_ref.add_view!
    second_ref.add_view!
    first_ref.reload.views.should == 2
  end

  describe "#valid_main_content_modules" do
    it "should returns all main content modules that pass ActiveRecord validations" do
      new_page = create(:page_with_parent, :content_modules => [create(:html_module)])
      page = Page.find(new_page.id)
      page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      page.valid_main_content_modules.size.should eql 2
    end
  end

  describe '#valid_header_content_modules' do
    it "should returns all header content modules that pass ActiveRecord validations" do
      new_page = create(:page_with_parent, :content_modules => [create(:html_module)])
      page = Page.find(new_page.id)
      page.content_module_links.create!(:layout_container => :header_content, :content_module => create(:past_campaign_module))
      page.content_module_links.create!(:layout_container => :header_content, :content_module => create(:past_campaign_module))
      page.valid_header_content_modules.size.should eql 2
    end
  end

  describe "#valid_aside_content_modules" do
    it "should returns all aside content modules that pass ActiveRecord validations" do
      new_page = create(:page_with_parent, :content_modules => [create(:html_module)])
      page = Page.find(new_page.id)
      page.content_module_links.create!(:layout_container => :aside_content, :content_module => create(:past_campaign_module))
      page.content_module_links.create!(:layout_container => :aside_content, :content_module => create(:past_campaign_module))
      page.content_module_links.create!(:layout_container => :main_content, :content_module => create(:past_campaign_module))
      page.valid_aside_content_modules.size.should eql 2
    end
  end

  describe "#cache_key" do
    it "should generate different cache keys even if different pages have the same friendly id" do
      page_1 = create(:page_with_parent, :name => "the page")
      page_2 = create(:page_with_parent, :name => "the page")

      page_1.cache_key.should_not eql page_2.cache_key
    end
  end

  describe '#validate_address_collection' do
    before do
      new_page = create(:page_with_parent)
      merch_module = create(:merch_module)
      @page = Page.find(new_page.id)
      @page.content_module_links.create!(:layout_container => :sidebar, :content_module => merch_module)
      @page.reload
    end

    it 'should not be valid if either postcode, street address or suburb are not hidden' do
      @page.required_user_details = {
          postcode_number: :optional,
          street_address: :hidden,
          suburb: :hidden
      }
      @page.should_not be_valid
    end

    it 'should be valid if postcode, street address and suburb are hidden' do
      @page.required_user_details = {
          postcode_number: :hidden,
          street_address: :hidden,
          suburb: :hidden
      }
      @page.should be_valid
    end
  end

  describe '#has_at_last_one_standfirst_module' do
    before do
      @standfirst_module = create(:standfirst_module)
      @page = create(:page_with_parent)
    end

    it 'should only allow zero Standfirst module' do
      @page.valid?.should be true
    end

    it 'should only allow one Standfirst module' do
      ContentModuleLink.create!(:content_module => @standfirst_module, :page => @page, :layout_container => :main_content)
      @m1 = create(:html_module)
      ContentModuleLink.create!(:content_module => @m1, :page => @page, :layout_container => :main_content)

      @page.valid?.should be true
    end

    it 'should not be valid if there is more than one standfirst module' do
      ContentModuleLink.create!(:content_module => @standfirst_module, :page => @page, :layout_container => :main_content)

      another_standfirst_module = create(:standfirst_module)
      ContentModuleLink.create!(:content_module => another_standfirst_module, :page => @page, :layout_container => :main_content)
      @page.valid?.should be false
    end
  end

  describe '#has_no_email_or_donation_modules_if_aside' do
    context 'has an aside' do
      before do
        @page = create(:page_with_parent)
        @page.content_module_links.create!(:layout_container => :aside_content, content_module: create(:past_campaign_module))
      end

      [:email_targets_module, :email_mp_module].each do |content_module|
        context "with #{content_module} in sidebar" do
          before do
            @page.content_module_links.create!(:layout_container => :sidebar, content_module: create(content_module))
          end
          specify { @page.should_not be_valid }
        end
      end

      [:donation_module, :tell_a_friend_module].each do |content_module|
        context "with #{content_module} in sidebar" do
          before do
            @page.content_module_links.create!(:layout_container => :sidebar, content_module: create(content_module))
          end
          specify { @page.should be_valid }
        end
      end
    end
  end

  context 'has no aside' do
    [:email_targets_module, :email_mp_module, :donation_module, :tell_a_friend_module].each do |content_module|
      context "with #{content_module} in sidebar" do
        before do
          @page = create(:page_with_parent)
          @page.content_module_links.create!(:layout_container => :sidebar, content_module: create(content_module))
        end
        specify { @page.should be_valid }
      end
    end
  end

  describe '#quarantined?' do
    let(:page){ create :page_with_parent }
    let(:sequence){ page.page_sequence }
    let(:campaign){ sequence.campaign }

    it 'defaults to false' do
      expect(page.quarantined?).to eq(false)
    end

    it 'can be set at the page_sequence level' do
      sequence.quarantined = true
      sequence.save!
      expect(page.quarantined?).to eq(true)
    end

    it 'can be set at the campaign level' do
      campaign.quarantined = true
      campaign.save!
      expect(page.quarantined?).to eq(true)
    end

    it 'can be set at both levels' do
      campaign.quarantined = true
      campaign.save
      sequence.quarantined = true
      sequence.save
      expect(page.quarantined?).to eq(true)
    end
  end
end 
