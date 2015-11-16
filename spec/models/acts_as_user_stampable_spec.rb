require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ActsAsUserStampable do
 
  describe Page do
    before do
      User.current_user = User.new(:first_name => 'Fred',
                                   :last_name => 'Smith', 
                                   :email => 'fred@example.com')
    end
    it "should populate created_by on create" do
      p = create(:page_with_parent)
      p.created_by.should eql('Fred Smith')
    end
    it "should update updated_by and leave created_by unchanged" do
      p = create(:page_with_parent)
      User.current_user = User.new(:first_name => 'John',
                                   :last_name => 'Howard', 
                                   :email => 'johhnie@example.com')
      p.name = "Blah blah blah"
      p.save
      p.created_by.should eql('Fred Smith')
      p.updated_by.should eql('John Howard')
    end
  end
end