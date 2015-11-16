require "spec_helper"

describe "mps/schedule_call_field.html.haml" do
  before :each do
    Timecop.travel "12 Feb 2015 11am"
  end
  
  it "should render 16 half hour time slices" do
    call_mp_module = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.today, :schedule_frequency => 30)
    render :partial => 'mps/schedule_call_field', :locals => { :call_mp_module => call_mp_module, :targets => 'tonyabbot@parliament.gov.au' }
    rendered.should have_selector 'option', :text => 'Today 12 Feb at 09:00am'
    rendered.should have_selector 'option', :text => 'Today 12 Feb at 09:30am'
  end
  
  it "should disable all the slices that are not available, and mark the members name on slices that are taken" do
    user = create :user, :first_name => 'Bang'
    call_mp_module = create(:call_mp_module, :schedule_calls => true, :schedule_start => Date.today, :schedule_end => Date.today, :schedule_frequency => 60)
    call_mp_module.stub(:slice_available?) { |targets, slice_from| ![Time.parse("9am"), Time.parse("10am")].include?(slice_from) }
    call_mp_module.stub(:slice_taken_by) { |targets, slice_from| slice_from == Time.parse("10am") ? user : nil }
    
    render :partial => 'mps/schedule_call_field', :locals => { :call_mp_module => call_mp_module, :targets => 'tonyabbot@parliament.gov.au' }
    rendered.should have_selector 'option[disabled]', :text => 'Today 12 Feb at 09:00am'
    rendered.should have_selector 'option[disabled]', :text => "Today 12 Feb at 10:00am\n☎ Bang"
    rendered.should have_selector 'option:not([disabled])', :text => 'Today 12 Feb at 11:00am'
  end
end