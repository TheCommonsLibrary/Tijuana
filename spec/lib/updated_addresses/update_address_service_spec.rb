require 'spec_helper'
require 'updated_addresses/update_address_service'
require 'updated_addresses/updated_address_row'
require 'csv'

describe UpdateAddressService do
  describe '#record_results' do
    it 'should update address correctly into Users' do
      User.find_or_create_by_email('user1@test.com')
      create(:postcode, number: '2010')

      csv_string = %[email,street_address,suburb,postcode\nuser1@test.com,123 Abc St.,Darlinghurst,2010]
      csv = CSV.parse(csv_string, :headers => true)

      record_row = UpdatedAddressRow.new(csv.first)
      UpdateAddressService.update_records record_row

      updated_record = User.first
      updated_record.street_address == '123 Abc St.'
      updated_record.suburb == 'Darlinghurst'
      updated_record.postcode.number == '2010'
      updated_record.address_validated_at == Time.now
    end

    it 'should update address correctly into Users if the postcode begins in 0' do
      User.find_or_create_by_email('user1@test.com')
      create(:postcode, number: '0810')

      csv_string = %[email,street_address,suburb,postcode\nuser1@test.com,587 Sunset Dr.,Millner,810]
      csv = CSV.parse(csv_string, :headers => true)

      record_row = UpdatedAddressRow.new(csv.first)
      UpdateAddressService.update_records record_row

      updated_record = User.first
      updated_record.street_address == '587 Sunset Dr.'
      updated_record.suburb == 'Millner'
      updated_record.postcode.number == '0810'
      updated_record.address_validated_at == Time.now
    end

    it 'should not update result if the user does not exist and throw an exception' do
      csv_string = %[email,street_address,suburb,postcode\nuser1@test.com,123 Abc St.,Darlinghurst,2010]
      csv = CSV.parse(csv_string, :headers => true)

      record_row = UpdatedAddressRow.new(csv.first)
      expect { UpdateAddressService.update_records record_row }.to raise_exception(RuntimeError, /User not found/)
      User.first.should be_nil
    end

    it 'should not update result if postcode does not exist and throw an exception' do
      User.find_or_create_by_email('user1@test.com')
      csv_string = %[email,street_address,suburb,postcode\nuser1@test.com,123 Abc St.,Darlinghurst,2010]
      csv = CSV.parse(csv_string, :headers => true)

      record_row = UpdatedAddressRow.new(csv.first)
      expect { UpdateAddressService.update_records record_row }.to raise_exception(RuntimeError, /Invalid postcode 2010/)
    end
  end
end
