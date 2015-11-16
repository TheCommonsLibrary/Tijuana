require 'spec_helper'
require 'rake'

describe 'import:campaign_tags' do
  include_context "rake"

  its(:prerequisites) { should include('environment')  }

  context 'with a csv of campaign tags in the correct format' do
    let!(:tags){ ['parents-and-children', 'economic-fairness', 'health-1'] }
    let!(:medicare_campaign){ create(:campaign, id: 255) }
    before{ subject.invoke 'campaign_tags.csv' }

    it 'should update the tags of matching campaigns' do
      Campaign.tagged_with(tags, :match_all => true).should == [medicare_campaign]
    end
  end
end
