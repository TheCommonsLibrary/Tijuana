require 'spec_helper'

describe UserCall do
  context 'scheduling calls' do
    before :each do
      @ask = create(:call_mp_module, :schedule_calls => true)
    end
    
    it 'should validate time slice is selected' do
      build(:user_call, :targets => 'tonyabbot@parliament.gov.au', :start_time => nil, :call_mp_module => @ask).should_not be_valid
      build(:user_call, :targets => 'tonyabbot@parliament.gov.au', :start_time => Date.today + 9.hours, :call_mp_module => @ask).should be_valid
    end
    
    it 'should validate that target is selected' do
      build(:user_call, :targets => nil, :call_mp_module => @ask).should_not be_valid
      build(:user_call, :targets => 'tonyabbot@parliament.gov.au', :call_mp_module => @ask).should be_valid
    end
  end
  
  context 'not scheduling calls' do
    before :each do
      @ask = create(:call_mp_module, :schedule_calls => false)
    end
    
    it 'should not validate start time unless call mp module is set to schedule calls' do
      build(:user_call, :targets => 'tonyabbot@parliament.gov.au', :start_time => nil, :call_mp_module => @ask).should be_valid
    end
  end 
end