require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

module ListCutter
  class DummyMemberValueRule < AbstractMemberValueRule
    def value_type
      return 'dummy'
    end

    def is_currency?
      false
    end

    def value_range_options
      [ [0], [1, 5] ]
    end
  end
end


describe ListCutter::DummyMemberValueRule do
  context 'validation' do
    it 'should be valid with range, no lower_limit, no upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '0', lower_limit: '', upper_limit: '').should be_valid
    end

    it 'should be valid with no range, min, no upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '-1', lower_limit: '1', upper_limit: '').should be_valid
    end

    it 'should be valid with no range, no min, upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '1').should be_valid
    end

    it 'should be valid with no range, lower_limit = upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '-1', lower_limit: '1', upper_limit: '1').should be_valid
    end

    it 'should be valid with no range, lower_limit < upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '-1', lower_limit: '4', upper_limit: '10').should be_valid
    end

    it 'should not be valid with no range, lower_limit > upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '-1', lower_limit: '2', upper_limit: '1').should_not be_valid
    end

    it 'should not be valid with no range, no lower_limit, no upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '-1', lower_limit: '', upper_limit: '').should_not be_valid
    end

    it 'should not be valid with range, lower_limit, no upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '0', lower_limit: '1', upper_limit: '').should_not be_valid
    end

    it 'should not be valid with range, no lower_limit, upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '0', lower_limit: '', upper_limit: '1').should_not be_valid
    end

    it 'should not be valid with range, lower_limit, upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '0', lower_limit: '1', upper_limit: '1').should_not be_valid
    end

    it 'should not be valid with no range, lower_limit is 0, no upper_limit' do
      ListCutter::DummyMemberValueRule.new(not: false, value_range: '-1', lower_limit: '0', upper_limit: '').should_not be_valid
    end
  end
end

