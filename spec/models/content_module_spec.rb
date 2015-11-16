# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ContentModule do
  describe "serialization/deserialization" do
    class DummyModule < ContentModule 
      option_fields :foo, :bar
    end
    class FooModule < ContentModule
      option_fields :harry
    end
    class MultipleFieldDeclarationsModule < ContentModule
      option_fields :the_first
      option_fields :the_second, :the_third
    end

    it "creates option attributes" do
      dummy = DummyModule.create!
      expect { dummy.foo = "value" }.not_to raise_error
      expect { dummy.xxx = "value" }.to raise_error(NoMethodError, /xxx=/)
    end

    it "saves and reloads serializable fields" do
      dm = DummyModule.create!(:foo => 'foo_value', :bar => 'bar_value')
      dm.foo.should eql('foo_value')
      dm.bar.should eql('bar_value')

      dm.reload

      dm.foo.should eql('foo_value')
      dm.bar.should eql('bar_value')
    end

    it "creates attributes only for the appropriate subclass" do
      foo = FooModule.create!
      expect { foo.harry = "sally" }.not_to raise_error
      expect { foo.foo = "bar"}.to raise_error(NoMethodError, /foo=/)
    end

    it "handles attributes sensibly without saving" do
      dm = DummyModule.new
      dm.foo = "bar"
      dm.save!
      dm.reload
      dm.foo.should == "bar"
    end
    
    it "allows multiple calls to option_fields" do
      mfdm = MultipleFieldDeclarationsModule.new(:the_first => 1, :the_second => 2, :the_third => 3)
      mfdm.save!
      mfdm = ContentModule.find(mfdm.id)
      mfdm.the_first.should == 1
      mfdm.the_second.should == 2
      mfdm.the_third.should == 3
    end
  end
  
  describe "public activity stream HTML" do
    before(:each) do
      @page = create(:page_with_parent)
    end
    
    it "substitutes $NAME for user first name" do
      dm = DummyModule.new(:public_activity_stream_template => "{NAME|Someone} is AWESOME")
      user = create(:user, :first_name => "rick")
      dm.public_activity_stream_html(user, @page).should == "<span class=\"name\">Rick</span> is AWESOME"
      user.first_name = nil
      dm.public_activity_stream_html(user, @page).should == "<span class=\"name\">Someone</span> is AWESOME"
    end
    
    it "links [linked text] to the first page in the sequence" do
      @page.update_attributes!(position: 2)
      first_page = create(:page, page_sequence: @page.page_sequence, position: 1)
      
      dm = DummyModule.new(:public_activity_stream_template => "This is a [link]")
      dm.public_activity_stream_html(create(:user), @page).should == "This is a <a href=\"/campaigns/#{@page.page_sequence.campaign.id}/#{@page.page_sequence.id}/#{first_page.id}\">link</a>"
    end
  end
  
  describe "bookmarking" do
    it "knows if it is bookmarked" do
      dm = DummyModule.create!
      dm.should_not be_bookmarked
      BookmarkedContentModule.create!(:content_module => dm, :name => "Useful widget")
      dm.reload
      dm.should be_bookmarked
    end
  end
  
  describe "linking to multiple pages" do
    it "knows if it is linked" do
      dm = DummyModule.create!
      dm.should_not be_linked
      
      ContentModuleLink.create!(:content_module => dm, :page => create(:page_with_parent))
      dm.reload
      dm.should_not be_linked      
      
      ContentModuleLink.create!(:content_module => dm, :page => create(:page_with_parent))
      dm.reload
      dm.should be_linked
    end
  end

  describe "first image" do
    it "returns the uri to first image in the module" do
      dm = DummyModule.create!(:content => '<h2>Hello</h2><div><br>something<div><img src="/images/some_header_image.png"/></div></div><table><tr><td></td></tr></table>')
      dm.first_image.should == "/images/some_header_image.png"
    end

    it "returns false if there is no first image" do
      dm = DummyModule.create!(:content => '<h2>Hello</h2><div><br>something<div>no image</div></div><table><tr><td></td></tr></table>')
      dm.first_image.should == false
    end

  end
  
  describe "does not add extra newlines or change html" do
    it "tidies content" do
      dm = DummyModule.create!(:content => "<ul><li>hi</li><li>bye</li></ul>")
      dm.content.should == "<ul><li>hi</li><li>bye</li></ul>"
    end
  end

  describe "content" do
    it "removes smart quotes" do
      dm = DummyModule.create!(:content => "“smart” double and ‘smart’ single quotes")
      dm.content.should == %Q{"smart" double and 'smart' single quotes}
    end
  end

  describe '#notify_user' do
    before do
      @dummy_module = DummyModule.create!
      @level = 'level'
      @title = 'title'
      @message = 'message'
    end

    it 'calls the proc' do
      notifier = double()
      @dummy_module.user_notifier = notifier
      notifier.should_receive(:call).with(@level, @title, @message)
      @dummy_module.notify_user(@level, @title, @message)
    end

    it 'raises exception if no notifier set' do
      expect {@dummy_module.notify_user(@level, @title, @message)}.to raise_error(RuntimeError, /No user notifier set/)
    end
  end

  describe '#notify_email' do
    before do
      @dummy_module = DummyModule.create!
      @error = double()
      @options = {data: 'message'}
    end

    it 'calls the proc' do
      notifier = double()
      @dummy_module.email_notifier = notifier
      error = double()
      notifier.should_receive(:call).with(@error, @options)
      @dummy_module.notify_email(@error, @options)
    end

    it 'raises exception if no notifier set' do
      expect {@dummy_module.notify_email(@error, @options)}.to raise_error(RuntimeError, /No email notifier/)
    end
  end

  describe '#create_action' do
    context 'action can save' do
      before :each do
        @action = double
        @action.should_receive(:save).and_return(true)
        @action.stub(:user)
        @action.stub(:page)
        @action.stub(:content_module)
        @action.stub(:email)
      end

      it 'should create a user activity event' do
        UserActivityEvent.should_receive(:action_taken!)
        subject.create_action(@action).should == @action
      end

      it 'should create a shared connection' do
        uae = double
        UserActivityEvent.stub(:action_taken!).and_return(uae)
        shared_connection = double
        shared_connection.stub(:valid?).and_return(true)
        shared_connection.should_receive(:user_activity_event=).with(uae)
        shared_connection.should_receive(:save!)
        subject.create_action(@action, {shared_connection: shared_connection}).should == @action
      end
    end

    context 'action cannot save' do
      it 'should return false' do
        action = double
        action.should_receive(:save).and_return(false)

        subject.create_action(action).should be false
      end
    end
  end

  describe '#if_trackable_donation_made' do
    let!(:non_donation_module){ DummyModule.create! }
    specify{ expect{ |b| non_donation_module.if_trackable_donation_made(&b) }.not_to yield_control }
  end
end
