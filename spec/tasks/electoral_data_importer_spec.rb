require File.dirname(__FILE__) + '/../spec_helper.rb'
require_relative "../../lib/tasks/electoral_data_importer"
require 'csv'

describe ElectoralDataImporter do
  before :each do
    @old_stdout = $stdout
    $stdout = StringIO.new
    electorate_importer = ElectoralDataImporter.new "db/csv"
    electorate_importer.import_electoral_data
  end

  after :each do
    $stdout = @old_stdout
  end

  it 'should import the right number of rows' do
    Jurisdiction.count.should == 9
    Party.count.should >= 44
    Postcode.count.should == 3145
    Electorate.count.should == 562
    Region.count.should == 42
    Mp.count.should == 404
    Senator.count.should == 153
    ActiveRecord::Base.connection.exec_query("select * from electorates_postcodes").rows.length.should == 7138
    ActiveRecord::Base.connection.exec_query("select * from postcodes_regions").rows.length.should == 6203
    ActiveRecord::Base.connection.exec_query(
      "select population, total_postcode_population, proportion from electorates_postcodes "\
      "where electorate_id = 48 and postcode_id = 1233 and population=1139 and total_postcode_population=1139 and proportion=1.00"
    ).rows.length.should == 1
  end

  it 'should add mailing address data to MPs' do
    abbott = Mp.find(1)
    expect(abbott.mailing_address).to eq('PO Box 450')
    expect(abbott.mailing_suburb).to eq('Manly')
    expect(abbott.mailing_state).to eq('NSW')
    expect(abbott.mailing_postcode).to eq('2095')
  end
end
