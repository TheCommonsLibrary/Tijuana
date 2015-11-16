require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe UserCsvFileReader do

  it 'should convert a CSV to an array' do
    rows = subject.csv_rows_to_array('db/csv/user_import_template.csv')
    rows.should be_an_instance_of(Array)
    rows.size.should == 1
    rows[0].size.should == 10
  end
end