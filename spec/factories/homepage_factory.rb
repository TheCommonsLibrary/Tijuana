FactoryGirl.define do
  factory(:homepage) do |f|
    f.banner_text  {'JOIN THE MOVEMENT OF {MEMBERCOUNT} AUSTRALIANS '}
    f.campaign_image { 'http://image.jpg' }
    f.campaign_url { '/campaigns/campaign' }
    f.campaign_alt_text { 'alt_text' }
    f.campaign2_image { 'http://image.jpg' }
    f.campaign2_url { '/campaigns/campaign' }
    f.campaign2_alt_text { 'alt_text' }
    f.campaign3_image { 'http://image.jpg' }
    f.campaign3_url { '/campaigns/campaign' }
    f.campaign3_alt_text { 'alt_text'}
  end
end