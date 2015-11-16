require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Theme do
  it "should give us select options" do
    happy = create(:theme, :name => "Happy", :display_name => "Happy")
    sad = create(:theme, :name => "Sad", :display_name => "Sad")
    Theme.select_options.should eql [["Happy",happy.id],["Sad",sad.id]]
  end
end
