require File.dirname(__FILE__) + '/../spec_helper.rb'

describe CallMPModule do

  it_behaves_like "a target representative finder"

  def validated_call_mp_module(attrs)
    etm = create(:call_mp_module)
    etm.update_attributes attrs
    etm.valid?
    etm
  end
  
  describe "validation" do
    it "should require a title between 3 and 128 characters" do
      validated_call_mp_module(:title => "Save the kittens!").should be_valid
      validated_call_mp_module(:title => "X" * 128).should be_valid
      validated_call_mp_module(:title => "X" * 129).should_not be_valid
      validated_call_mp_module(:title => "AB").should_not be_valid
    end
    
    it "should require a button text between 1 and 64 characters" do
      validated_call_mp_module(:button_text => "Save the kittens!").should be_valid
      validated_call_mp_module(:button_text => "X" * 64).should be_valid
      validated_call_mp_module(:button_text => "X" * 65).should_not be_valid
      validated_call_mp_module(:button_text => "").should_not be_valid
    end

    it "should only allow valid values for the target_phone option" do
      validated_call_mp_module(:target_phone => "parliament").should be_valid
      validated_call_mp_module(:target_phone => "office").should be_valid
      validated_call_mp_module(:target_phone => "anything_else").should_not be_valid
    end

    context "when a jurisdiction with target parties is selected" do
      let!(:jurisdiction) { create(:federal_jurisdiction_with_parties) }

      it "should require at least one target party to be selected" do
        validated_call_mp_module(:target_party_ids => {1 => '1'}).should be_valid
        validated_call_mp_module(:target_party_ids => {}).should_not be_valid
      end
      
      it 'should not require a parties to be chosen if arbitrary target' do
        validated_call_mp_module(:arbitrary_target => true, :target_party_ids => {}).should be_valid
      end
    end

    context "when visiting the target" do
      it 'should require the target_phone to be office' do
        validated_call_mp_module(target_phone: 'parliament', contact_method: 'visit').should_not be_valid
      end
    end

    context "when mailing the target" do
      it 'should require the target_phone to be office' do
        validated_call_mp_module(target_phone: 'parliament', contact_method: 'mail').should_not be_valid
      end
    end
    
    it 'should require schedule fields when scheduling calls' do
      validated_call_mp_module(:schedule_calls => true, :schedule_start => nil).should_not be_valid
      validated_call_mp_module(:schedule_calls => true, :schedule_end => nil).should_not be_valid
      validated_call_mp_module(:schedule_calls => true, :schedule_frequency => nil).should_not be_valid
      validated_call_mp_module(:schedule_calls => false, :schedule_start => nil).should be_valid
      validated_call_mp_module(:schedule_calls => false, :schedule_end => nil).should be_valid
      validated_call_mp_module(:schedule_calls => false, :schedule_frequency => nil).should be_valid
    end
    
    it 'should require schedule end to be on the same day or greater then schedule start' do
      validated_call_mp_module(:schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.yesterday).should_not be_valid
      validated_call_mp_module(:schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.today).should be_valid
      validated_call_mp_module(:schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.tomorrow).should be_valid
    end
  end
  
  describe "defaults" do
    it "should set appropriate defaults" do
      page = create(:page_with_parent)
      etm = CallMPModule.create!(:title => "A Title")
      ContentModuleLink.create!(:page => page, :content_module => etm)
      etm.button_text.should eql('I called!')
      etm.display_defaults.should == true
      etm.target_party_ids.should be_empty
      etm.target_senate.should be true
      etm.target_phone.to_sym.should eql :parliament
    end
  end

  describe '#show_steps?' do
    it 'should return true' do
      subject.show_steps = '1'
      subject.show_steps?.should be true
    end

    it 'should return false' do
      subject.show_steps = '0'
      subject.show_steps?.should be false
    end
  end
  
  describe "taking an action" do
    before do
      @page = create(:page_with_parent)
    end
    
    it "should send an email as part of taking the action and record what was sent" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:call_mp_module)

      ask.update_action_attributes_and_validate(:targets => "moo@homes.com")
      ask.take_action(user, @page)

      user_call = UserCall.first
      user_call.targets.should == "moo@homes.com"
    end

    it 'should create a user activity event' do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:call_mp_module)

      UserActivityEvent.should_receive(:action_taken!).with(user, @page, ask, an_instance_of(UserCall), nil, nil, nil)

      ask.update_action_attributes_and_validate(:targets => "moo@homes.com")
      ask.take_action(user, @page)
    end

  end
  
  describe "target parties" do
    it "should accept a hash for the selected parties and return an array" do
      etm = CallMPModule.create
      etm.target_party_ids = {"1" => "1", "2" => "0", "3" => "1", "4" => "1", "5" => "0"}
      etm.target_party_ids.should == [1,3,4]
    end
  end

  describe "Scheduling" do
    it "should generate time slices between start and end date" do
      Timecop.freeze('3 Feb 2016') do
        ask = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.today, :schedule_frequency => 60)
        ask.time_slices.should == [
          [Time.parse("9am") ,Time.parse("10am")],
          [Time.parse("10am") ,Time.parse("11am")],
          [Time.parse("11am") ,Time.parse("12pm")],
          [Time.parse("12pm") ,Time.parse("1pm")],
          [Time.parse("1pm") ,Time.parse("2pm")],
          [Time.parse("2pm") ,Time.parse("3pm")],
          [Time.parse("3pm") ,Time.parse("4pm")],
          [Time.parse("4pm") ,Time.parse("5pm")],
        ]
      end
    end

    it "should exclude times on the weekend" do
      Timecop.freeze('14 Feb 2015') do
        ask = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.yesterday, :schedule_end => Date.today + 2, :schedule_frequency => 60)
        ask.time_slices.should == [
          [Time.parse("16 Feb 2015 9am") ,Time.parse("16 Feb 2015 10am")],
          [Time.parse("16 Feb 2015 10am") ,Time.parse("16 Feb 2015 11am")],
          [Time.parse("16 Feb 2015 11am") ,Time.parse("16 Feb 2015 12pm")],
          [Time.parse("16 Feb 2015 12pm") ,Time.parse("16 Feb 2015 1pm")],
          [Time.parse("16 Feb 2015 1pm") ,Time.parse("16 Feb 2015 2pm")],
          [Time.parse("16 Feb 2015 2pm") ,Time.parse("16 Feb 2015 3pm")],
          [Time.parse("16 Feb 2015 3pm") ,Time.parse("16 Feb 2015 4pm")],
          [Time.parse("16 Feb 2015 4pm") ,Time.parse("16 Feb 2015 5pm")]
        ]
      end
    end
    
    it "should generate time slices between start and end date with a frequency of 30 mins" do
      Timecop.freeze('3 Feb 2016') do
        ask = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.today, :schedule_frequency => 30)
        ask.time_slices.should == [
          [Time.parse("9am") ,Time.parse("9:30am")],
          [Time.parse("9:30am") ,Time.parse("10am")],
          [Time.parse("10am") ,Time.parse("10:30am")],
          [Time.parse("10:30am") ,Time.parse("11am")],
          [Time.parse("11am") ,Time.parse("11:30am")],
          [Time.parse("11:30am") ,Time.parse("12pm")],
          [Time.parse("12pm") ,Time.parse("12:30pm")],
          [Time.parse("12:30pm") ,Time.parse("1pm")],
          [Time.parse("1pm") ,Time.parse("1:30pm")],
          [Time.parse("1:30pm") ,Time.parse("2pm")],
          [Time.parse("2pm") ,Time.parse("2:30pm")],
          [Time.parse("2:30pm") ,Time.parse("3pm")],
          [Time.parse("3pm") ,Time.parse("3:30pm")],
          [Time.parse("3:30pm") ,Time.parse("4pm")],
          [Time.parse("4pm") ,Time.parse("4:30pm")],
          [Time.parse("4:30pm") ,Time.parse("5pm")],
        ]
      end
    end
  
    it 'should return number of time slices in a day' do
      Timecop.freeze('3 Feb 2016') do
        ask = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.today, :schedule_frequency => 30)
        ask.time_slices_in_a_day.should == 16
      end
    end
    
    it 'should return only time slices from today forward (but show slices from earlier in the day)' do
      Timecop.freeze('12 Feb 2015') do
        ask = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.yesterday, :schedule_end => Date.today, :schedule_frequency => 60)
        ask.time_slices.should == [
          [Time.parse("12 Feb 2015 9am") ,Time.parse("12 Feb 2015 10am")],
          [Time.parse("12 Feb 2015 10am") ,Time.parse("12 Feb 2015 11am")],
          [Time.parse("12 Feb 2015 11am") ,Time.parse("12 Feb 2015 12pm")],
          [Time.parse("12 Feb 2015 12pm") ,Time.parse("12 Feb 2015 1pm")],
          [Time.parse("12 Feb 2015 1pm") ,Time.parse("12 Feb 2015 2pm")],
          [Time.parse("12 Feb 2015 2pm") ,Time.parse("12 Feb 2015 3pm")],
          [Time.parse("12 Feb 2015 3pm") ,Time.parse("12 Feb 2015 4pm")],
          [Time.parse("12 Feb 2015 4pm") ,Time.parse("12 Feb 2015 5pm")]
        ]
      end
    end
    
    it 'should return only time slices from today forward (but show slices from earlier in the day)' do
      Timecop.freeze('12 Feb 2015') do
        ask = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.tomorrow, :schedule_end => Date.tomorrow, :schedule_frequency => 60)
        ask.time_slices.should == [
          [Time.parse("13 Feb 2015 9am") ,Time.parse("13 Feb 2015 10am")],
          [Time.parse("13 Feb 2015 10am") ,Time.parse("13 Feb 2015 11am")],
          [Time.parse("13 Feb 2015 11am") ,Time.parse("13 Feb 2015 12pm")],
          [Time.parse("13 Feb 2015 12pm") ,Time.parse("13 Feb 2015 1pm")],
          [Time.parse("13 Feb 2015 1pm") ,Time.parse("13 Feb 2015 2pm")],
          [Time.parse("13 Feb 2015 2pm") ,Time.parse("13 Feb 2015 3pm")],
          [Time.parse("13 Feb 2015 3pm") ,Time.parse("13 Feb 2015 4pm")],
          [Time.parse("13 Feb 2015 4pm") ,Time.parse("13 Feb 2015 5pm")]
        ]
      end
    end
    
    describe 'user scheduling call' do
      before :each do
        Timecop.freeze '12 Feb 2015 11am'
        @page = create :page_with_parent
        @user = create(:user, :email => 'noone@example.com')
        @ask = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.today, :schedule_frequency => 60)
      end
      
      it "should indicate if time slice is taken by another user" do
        @ask.update_action_attributes_and_validate(:targets => 'tonyabbot@parliament.gov.au', :mp => { :start_time => Time.parse("4pm") })
        @ask.take_action @user, @page
        @ask.slice_available?('tonyabbot@parliament.gov.au', Time.parse("4pm")).should == false
        @ask.slice_taken_by('tonyabbot@parliament.gov.au', Time.parse("4pm")).should == @user
        @ask.slice_available?('tonyabbot@parliament.gov.au', Time.parse("2pm")).should == true
        @ask.slice_taken_by('tonyabbot@parliament.gov.au', Time.parse("2pm")).should == nil
      end
      
      it "should allow a slice to be booked up until the end time of the slice is past" do
        Timecop.freeze '12 Feb 2015 3pm'
        @ask.slice_available?('tonyabbot@parliament.gov.au', Time.parse("4pm")).should == true
        Timecop.freeze '12 Feb 2015 4pm'
        @ask.slice_available?('tonyabbot@parliament.gov.au', Time.parse("4pm")).should == true
        Timecop.freeze '12 Feb 2015 4:59pm'
        @ask.slice_available?('tonyabbot@parliament.gov.au', Time.parse("4pm")).should == true
        Timecop.freeze '12 Feb 2015 5pm'
        @ask.slice_available?('tonyabbot@parliament.gov.au', Time.parse("4pm")).should == false
        Timecop.freeze '12 Feb 2015 5:01pm'
        @ask.slice_available?('tonyabbot@parliament.gov.au', Time.parse("4pm")).should == false
      end
      
      it 'should restrict member from scheduling another call with the same target' do
        expect do
          ['tonyabbot@parliament.gov.au', 'tonyabbot@parliament.gov.au'].each do |email|
            params = { :targets => email, :mp => { :start_time => Time.parse("4pm") } }
            @ask.update_action_attributes_and_validate params
            @ask.take_action @user, @page, nil, params
          end
        end.to raise_error DuplicateActionTakenError
      end
      
      it 'should allow member to scheduling another call with a different target' do
        expect do
          ['tonyabbot@parliament.gov.au', 'malcomturnbul@parliament.gov.au'].each do |email|
            params = { :targets => email, :mp => { :start_time => Time.parse("4pm") } }
            @ask.update_action_attributes_and_validate params
            @ask.take_action @user, @page, nil, params
          end
        end.not_to raise_error
      end
    end
  end
end
