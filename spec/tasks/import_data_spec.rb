require 'spec_helper'
require 'rake'

describe "should import data from csv correctly", speed: 'slow' do
  include_context "capture_system_io"

  before :all do
    rake = Rake::Application.new
    Rake.application = rake
    Rake::Task.define_task(:environment)
    load "#{Rails.root}/lib/tasks/import_data.rake"
    rake["import:electoral:data"].invoke
  end

  after :all do
    tables_to_clear = [Party, Electorate, Region, Mp, Senator, Jurisdiction, Postcode, Theme]
    for table in tables_to_clear
      puts "deleting #{table.name}"
      table.delete_all
    end
  end

  it 'should import the right number of rows' do
    Region.count.should == 42
    Electorate.count.should == 562
    Jurisdiction.count.should == 9
  end
end

describe "adding themes", speed: 'slow' do
  include_context "capture_system_io"

  after :all do
    puts "deleting Theme" 
    Theme.delete_all
  end

  before :each do
    rake = Rake::Application.new
    Rake.application = rake
    Rake::Task.define_task(:environment)
    load "#{Rails.root}/lib/tasks/import_data.rake"
    rake["import:themes"].invoke
  end

  it "update to only new themes" do 
    default = Theme.find(1)
    default.name.should eql "application"
    default.display_name.should eql "Default"
    cr = Theme.find(2)
    cr.name.should eql "communityrun"
    cr.display_name.should eql "CommunityRun"
  end
end
