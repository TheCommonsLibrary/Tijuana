require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe MpActionHelper do
  let(:senator) { create(:senator, :first_name => "Mr.Nice", :last_name => "Guy", :office_phone => "777", :parliament_phone => "888") }
  let(:mp) { create(:mp, :first_name => "Mr.Big", :last_name => "Shot", :office_phone => "666", :parliament_phone => "555") }
  let(:call_mp_module) { create(:call_mp_module) }
  let(:email_mp_module) { create(:email_mp_module) }

  describe '#evaluate_fallback_action_message' do
    context 'call mp module' do
      it "should evaluate the senator's message" do
        helper.should_receive(:call_mp_fallback_template).with(call_mp_module, mp, senator)
        helper.evaluate_fallback_action_message(call_mp_module, mp, senator)
      end

      context 'email mp module' do
        it "should evaluate the senator's message" do
          expected_msg_for_email_mp = "#{mp.full_name} does not represent one of the target parties of this campaign, your email will go to Senator #{senator.full_name} instead."
          helper.evaluate_fallback_action_message(email_mp_module, mp, senator).should eql expected_msg_for_email_mp
        end
      end
    end
  end

  describe '#call_mp_fallback_template' do
    it "should return fallback message" do
      helper.should_receive(:get_phone).with(call_mp_module, senator)
      msg = helper.evaluate_fallback_action_message(call_mp_module, mp, senator)
      msg.should match /Mr.Big Shot does not represent one of the target parties/
      msg.should match /Please call your Senator/
      msg.should match /Mr.Nice Guy/
    end
  end

  describe '#get_phone' do
    context 'parliament' do
      it 'should return parliament number' do
        call_mp_module.target_phone = :parliament
        helper.send(:get_phone, call_mp_module, mp).should == mp.parliament_phone
      end
    end

    context 'office' do
      it 'should return office number' do
        call_mp_module.target_phone = :office
        helper.send(:get_phone, call_mp_module, mp).should == mp.office_phone
      end
    end
  end
  
  it 'should format time slices' do
    Timecop.freeze Time.parse("12 Feb 2015 9am") do
      helper.format_time_slice(Time.now).should == "Today 12 Feb at 09:00am"
      helper.format_time_slice(1.day.from_now).should == "Fri 13 Feb at 09:00am"
    end
  end
end
