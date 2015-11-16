require 'spec_helper'

describe AcquisitionSource do
  describe "#name" do
    it 'should validate that it only contains ascii characters' do
      expect(build(:acquisition_source, name: 'test - long dash')).to be_valid
      expect(build(:acquisition_source, name: 'test — long dash')).to_not be_valid
    end
  end
  describe '#slug' do
    it 'should be generated from source, medium, content and name' do
      expect(create(:acquisition_source).slug).to eq('fb-org-test_name_with-v1')
    end

    it 'should be unique' do
      create(:acquisition_source)
      duplicate = build(:acquisition_source)
      expect(duplicate).to_not be_valid
      expect(duplicate.errors.full_messages.grep(/already exists/)).to be_any
    end

    it 'should allow the same name if the other fields are unique' do
      create(:acquisition_source)
      duplicate = build(:acquisition_source, medium: 'cpc')
      expect(duplicate).to be_valid
    end

    it 'should allow numbers in the slug' do
      expect(create(:acquisition_source, medium: 'cpc', name: '123').slug).to match(/123/)
    end
  end

  describe "*_label method missing" do
    it 'should return the nice name for the value' do
      source = create(:acquisition_source)
      source.source_label.should == 'Facebook'
      source.medium_label.should == 'Organic'
      source.content_label.should == 'Version 1'
    end
  end

end
