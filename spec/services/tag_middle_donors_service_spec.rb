require 'spec_helper'

describe TagMiddleDonorsService do

  context "with a donor with valid donation of $250" do
    let!(:donation_of_250){ create(:donation, amount_in_cents: 25000) }
    let(:donor){ donation_of_250.user }
    let!(:transaction){ create(:transaction, donation: donation_of_250, amount_in_cents: 25000) }
    it "should tag them with `middledonor`" do
      TagMiddleDonorsService.tag!
      expect(donor.tag_list).to be_include('middledonor')
    end

    context "with an existing majordonor tag" do
      before do
        donor.tag_list.add('majordonor')
        donor.save!
      end
      it "should not tag them as middle donor" do
        TagMiddleDonorsService.tag!
        donor.reload
        expect(donor.tag_list).to eq(['majordonor'])
      end
    end 
  end

  context 'with a donor with $5000 donation' do
    let!(:donation_of_5000){ create(:donation, amount_in_cents: 500000) }
    let!(:transaction){ create(:transaction, donation: donation_of_5000, amount_in_cents: 500000) }
    let(:donor){ donation_of_5000.user }
    it 'should add a majordonor tag' do
      TagMiddleDonorsService.tag!
      donor.reload
      expect(donor.tag_list).to eq(['majordonor'])
    end

    context "with user with a pre existing `middledonor`" do
      before do
        donor.tag_list.add('middledonor')
        donor.save!
      end
      it 'should remove the middledonor tag' do
        TagMiddleDonorsService.tag!
        donor.reload
        expect(donor.tag_list).to eq(['majordonor'])
      end
    end
  end
  
  context "with a major donor tag but not donation" do
    let!(:majordonor){
      u = create(:user)
      u.tag_list.add('majordonor')
      u.save!
      u
    }
    it "should keep the major donor tag" do
      TagMiddleDonorsService.tag!
      majordonor.reload
      expect(majordonor.tag_list).to be_include('majordonor')
    end
  end
end
