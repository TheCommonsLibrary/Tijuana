require 'spec_helper'

describe ExecutesEscapedSql do
  
  # pretty benign attack as AR/mysql guards against ; anyways
  it 'should escape sql params' do
    create :user, :email => 'joe@test.com'
    email = "'joe@test.com' and 1 = 1 #"
    result = ActiveRecord::Base.connection.execute "select * from users where email = #{email}"
    result.count.should == 1
    result = ActiveRecord::Base.execute_escaped "select * from users where email = ?", email
    result.count.should == 0
  end
end