require 'spec_helper'

describe PostalAddress do
  describe 'validation' do
    describe '#initialize' do
      before :each do
        subject.search_outcome = 'manual'
        params = {:street_address => "1 James st", :postcode_number => '2010', :suburb => 'Surry Hills',
                  :search_outcome => 'manual', :state => 'NSW'}
        @postal_address = PostalAddress.new(params)
      end

      specify { subject.should have(1).error_on(:street_address) }
      specify { subject.should have(1).error_on(:suburb) }
      specify { subject.should have(1).error_on(:postcode_number) }

      it 'should add an error for an invalid postcode' do
        @postal_address.postcode_number = 'asdf'
        @postal_address.should have(1).errors_on(:postcode_number)
      end

      it 'should not add an error for a valid 4 digit postcode' do
        @postal_address.postcode_number = '2000'
        @postal_address.errors[:postcode_number].size.should == 0
      end

      it 'should not add an error for a valid 3 digit postcode' do
        @postal_address.postcode_number = '800'
        @postal_address.errors[:postcode_number].size.should == 0
      end

      it 'should record all postal address attributes' do
        @postal_address.street_address.should == '1 James st'
        @postal_address.postcode_number.should == '2010'
        @postal_address.suburb.should == 'Surry Hills'
        @postal_address.search_outcome.should == 'manual'
        @postal_address.state.should == 'NSW'
      end

      it 'should raise an exception if unknown parameters are passed in' do
        params = {something: 'a thing'}
        expect { PostalAddress.new(params) }.to raise_exception(NoMethodError, /something=/)
      end
    end
  end
end
