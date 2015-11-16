require 'spec_helper'

shared_examples_for "a talking point module" do |init_params|

  before :each do
    if init_params
      @object_with_talking_points = create(described_class.to_s.underscore.to_sym, init_params)
    else
      @object_with_talking_points = create(described_class.to_s.underscore.to_sym)
    end
    @object_with_talking_points.talking_points.create(short_description: "Short", long_description: "Long long long")
  end

  describe "default_number_of_talking_points" do
    it "supplements existing talking points to the default number with blanks" do
      #when
      @object_with_talking_points.default_number_of_talking_points(2)
      #then
      @object_with_talking_points.talking_points.length.should == 2
      @object_with_talking_points.talking_points[1].short_description.should be_blank
      @object_with_talking_points.talking_points[1].long_description.should be_blank
    end
  end

  describe "saving" do
    it "deletes empty talking points" do
      #when
      @object_with_talking_points.save
      #then
      @object_with_talking_points.talking_points.length.should == 1
      @object_with_talking_points.talking_points[0].short_description.should_not be_blank
      @object_with_talking_points.talking_points[0].long_description.should_not be_blank
    end
  end
end
