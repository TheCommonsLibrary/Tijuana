require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe UserCsvFileImporter do

  before :each do
    create(:user, :email => '1@new.user', :street_address => '1 Street', :id => 1)
    create(:user, :email => '2@new.user', :street_address => '2 Street', :id => 2)
    tagged_user = create(:user, :email => '3@gmail.com', :street_address => '3 Street', :id => 3)
    tagged_user.update_attributes :tag_list => 'existing tag'
  end
  
  it 'should not be able to clear data - it is too risky' do
    csv_row = csv_row 'identifier' => '1@new.user', 'street_address' => ''
    importer = UserCsvFileImporter.new csv_row, 'identifier' => 'email'
    importer.each { }
    User.find_by_email('1@new.user').street_address.should == '1 Street'
  end

  context 'send welcome email' do
    before do
      @params = {'identifier' => 'email', 'welcome_email' => 'on'}
    end

    it 'enabled' do
      importer = UserCsvFileImporter.new(users_to_import_by_email, @params)
      UserMailer.should_receive(:welcome_to_getup).with(an_instance_of(User)).exactly(3).times
      importer.each { }
    end

    it 'disabled' do
      @params['welcome_email'] = nil
      importer = UserCsvFileImporter.new(users_to_import_by_email, @params)
      UserMailer.should_not_receive(:welcome_to_getup)
      importer.each { }
    end
  end

  context 'import users with email identifier' do
    subject { UserCsvFileImporter.new(users_to_import_by_email, {'identifier' => 'email' }) }

    it 'should insert non-existing users into to the database' do
      userCount = User.all.size
      subject.each { }
      User.all.size.should == userCount + 3
    end

    it 'should set the source as csv_import' do
      subject.each {}
      UserActivityEvent.find_all_by_source('csv_import').count.should == 3
    end

    it 'should update existing users in the database' do
      UserMailer.should_not_receive(:welcome_to_getup)
      subject.each { }
      User.find_by_email('3@gmail.com').street_address.should == '3 Road'
    end

    it 'should output the right results' do
      output = subject.each { }
      output[1].last.should == 'New'
      output[2].last.should == 'New'
      output[3].last.should == 'Update'
      output[4].last.should == 'New'
    end
  end

  context 'import user with mysql primary key identifier' do
    subject { UserCsvFileImporter.new(users_to_import_by_id, {'identifier' => 'id'}) }

    it 'should find and update user by id' do
      subject.each { }
      user = User.find_by_email('3@gmail.com')
      user.street_address.should == '3 Road'
    end

    it 'should not insert rows' do
      userCount = User.all.size
      subject.each { }
      User.all.size.should == userCount
    end

    it 'should append the right result for every import row' do
      output = subject.each { }
      output[1].last.should == 'Update'
      output[2].last.should == 'Update'
      output[3].last.should == 'Update'
      output[4].last.should =~ /Error/
    end
  end

  context 'import users by token identifier' do
    subject { UserCsvFileImporter.new(users_to_import_by_token, {'identifier' => 'token'}) }

    it 'should find and update users using the token' do
      subject.each { }
      user = User.find_by_email('3@gmail.com')
      user.street_address.should == '3 Road'
    end

    it 'should not insert rows' do
      userCount = User.all.size
      subject.each { }
      User.all.size.should == userCount
    end

    it 'should have a result for every import row' do
      output = subject.each { }
      output[1].last.should == 'Update'
      output[2].last.should == 'Update'
      output[3].last.should == 'Update'
      output[4].last.should =~ /Error/
    end
  end

  context 'preview mode' do
    let(:params) {{'identifier' => 'email', 'preview' => 'on'}}
    subject { UserCsvFileImporter.new(users_to_import_by_email, params) }

    it 'should not import if in preview mode' do
      UserMailer.should_not_receive(:welcome_to_getup)
      output = subject.each { }
      User.all.size.should == 3
    end
  end

  def assert_results(results, expected) 
    results.shift #header
    results.each_with_index do |row, i|
      row[9].should == expected[i]
    end
  end

  context 'quarantine mode' do
    let(:params) {{'identifier' => 'email', 'quarantine' => 'on'}}
    subject { UserCsvFileImporter.new(users_to_import_by_email, params)}

    it 'should quarantine a new user' do
      results = subject.each {}
      assert_results(results, ['New','New','Update','New'])
      user = User.find_by_email('4@gmail.com')
      expect(user).to be_is_member
      expect(user).to be_quarantined
      expect(user.user_activity_events.quarantines.where(source: 'import').count).to eq(1)
    end

    it 'should not add existing user to quarantine' do
      user = User.find_by_email('3@gmail.com')
      expect(user).to_not be_quarantined
      subject.each {}
      user.reload.is_member
      expect(user).to be_is_member
    end

    it "should not send welcome email" do
      UserMailer.should_not_receive(:welcome_to_getup)
      subject.each {}
    end

    it "should not send welcome email even when welcome email is on" do
      UserMailer.should_not_receive(:welcome_to_getup)
      params.merge!({'welcome_email' => 'on'})
      subject.each {}
    end
  end

  context 'has user tags' do
    let(:params) {{'identifier' => 'email', 'tags' => 'tag 1, tag 2'}}
    subject { UserCsvFileImporter.new(users_to_import_by_email, params)}

    it 'should add tags to new user' do
      subject.each {}
      user = User.find_by_email('4@gmail.com')
      user.tag_list.should == ['tag 1' , 'tag 2']
    end

    it 'should update tags to existing user' do
      subject.each {}
      user = User.find_by_email('3@gmail.com')
      user.tag_list.should == ['existing tag', 'tag 1', 'tag 2']
    end
  end

  context 'has no user tags' do
    subject { UserCsvFileImporter.new(users_to_import_by_email, {'identifier' => 'email'})}

    it 'should add no tags to new user' do
      subject.each {}
      user = User.find_by_email('4@gmail.com')
      user.tag_list.should be_empty
    end

    it 'should not add any new tags to existing user' do
      subject.each {}
      user = User.find_by_email('3@gmail.com')
      user.tag_list.should == ['existing tag']
    end
  end
  
  def csv_row(attributes)
    headers = %w(identifier first_name last_name mobile_number home_number street_address suburb country_iso postcode result)
    row = headers.map { |h| attributes[h] }
    [headers, row]
  end

  def users_to_import_by_email
    file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'bulk_users_with_id_email.csv'), 'text/csv')
    reader = UserCsvFileReader.new
    reader.csv_rows_to_array(file.path.to_s)
  end

  def users_to_import_by_id
    file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'bulk_users_with_id_id.csv'), 'text/csv')
    reader = UserCsvFileReader.new
    reader.csv_rows_to_array(file.path.to_s)
  end

  def users_to_import_by_token
    file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'bulk_users_with_id_token.csv'), 'text/csv')
    reader = UserCsvFileReader.new
    reader.csv_rows_to_array(file.path.to_s)
  end
end
