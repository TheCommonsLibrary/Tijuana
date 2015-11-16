require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), '../../lib/hash_truncate')

describe HashTruncate do

  it 'should truncate all values greater than 10 characters in hash with depth of 1' do
    depth = 1
    character_limit = 10
    hash = {
      key1: 'data1',
      key2: 'data_copy2',
      key3: 'data_length_than_10'
    }

    results = HashTruncate.truncate!(hash, depth, character_limit)
    results[:key1].should == 'data1'
    results[:key2].should == 'data_copy2'
    results[:key3].should == 'data_lengt'
  end

  it 'should truncate all values greater than 10 characters in hash with depth of 2' do
    depth = 2
    character_limit = 10
    hash = {
      key1: 'data1',
      key2: {
        key1: 1,
        key2: 'data_copy2',
        key3: 'data_length_than_10'
      },
      key3: 'data_length_than_10'
    }

    results = HashTruncate.truncate!(hash, depth, character_limit)
    results[:key1].should == 'data1'
    results[:key3].should == 'data_lengt'
    results[:key2][:key1].should == '1'
    results[:key2][:key2].should == 'data_copy2'
    results[:key2][:key3].should == 'data_lengt'
  end

  it 'should truncate all values greater than 5 characters and remove all nested hashes below depth 2' do
    depth = 2
    character_limit = 5
    hash = {
      key1: 'data1',
      key2: {
        key1: 'data1',
        key2: {
          key1: 'data1',
          key2: 'data_copy2',
          key3: 'data_length_than_10'
        },
        key3: 'data_length_than_10'
      },
      key3: 'data_length_than_10'
    }

    results = HashTruncate.truncate!(hash, depth, character_limit)
    results[:key1].should == 'data1'
    results[:key3].should == 'data_'
    results[:key2][:key1].should == 'data1'
    results[:key2][:key3].should == 'data_'
    results[:key2][:key2][:key1].should == 'ELIDED'
    results[:key2][:key2][:key2].should == 'ELIDED'
    results[:key2][:key2][:key3].should == 'ELIDED'
  end

end