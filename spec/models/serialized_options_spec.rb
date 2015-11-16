require 'spec_helper'

describe "SerializedOptions" do
  class SomeThing
    attr_accessor :updated_at
    def self.serialize(field)
      attr_accessor field
    end
    
    include SerializedOptions
    
    typed_option_field :somedate, :date
    typed_option_field :someboolean, :boolean
  end
  
  it 'should type cast string values so they are stored in the correct type' do
    SomeThing.new.tap { |st| st.somedate = "11 June 2015" }.somedate.should == Date.parse("11 June 2015")
    SomeThing.new.tap { |st| st.someboolean = "1" }.someboolean.should == true
  end
end