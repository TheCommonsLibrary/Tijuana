require 'spec_helper'

describe 'common/target_tracking' do

  it 'should NOT trigger a FB and GA custom events by default' do
    render :partial => 'common/target_tracking'
    expect(rendered).to_not be_include("fbq.push(['track', 'target_view']);");
    expect(rendered).to_not be_include("ga('send', 'event', 'target', 'view', 'target_view');");
  end
    
  context 'accessed from a govt IP range' do

    before{
      AppConstants.stub(:facebook_tracking_id).and_return(1)
    }

    it 'should trigger a FB and GA custom events' do
      render :partial => 'common/target_tracking', locals: {request: double(remote_ip: AppConstants.govt_ips.split(',').first)}
      expect(rendered).to be_include("fbq.push(['track', 'target_view']);");
      expect(rendered).to be_include("ga('send', 'event', 'target', 'view', 'target_view');");
    end
  end
end
