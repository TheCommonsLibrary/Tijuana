require_relative '../support/electoral_seeder'

module SeedHelper
  def seed
    User.create!(:first_name => "admin", :last_name => "admin", :email => 'admin@admin.com', :password=>'password', :is_admin => true)
    User.create!(:first_name => "Mel", :last_name => "Member", :email => 'mel@member.com', :password=>'password')
    User.create!(:first_name => "Matt", :last_name => "Member", :email => 'matt@member.com', :password=>'password')
    
    Theme.where(name: "application", display_name: "Default").first_or_create
    
    Homepage.create!(
      :banner_text => "{MEMBERCOUNT} AUSSIES WHO ALL FIGHT FOR FAIRNESS, SUSTAINABILITY & SOCIAL JUSTICE!",
      :campaign_image => "/images/homepage-campaign.jpg",
      :campaign_url => "/donate",
      :campaign_alt_text => "Donate to GetUp!",
      :campaign2_image => "/images/homepage-campaign2-placeholder.jpg",
      :campaign2_url => "/donate",
      :campaign2_alt_text => "Campaign2",
      :campaign3_image => "/images/homepage-campaign3-placeholder.jpg",
      :campaign3_url => "/donate",
      :campaign3_alt_text => "Campaign3"
    )
    
    MemberCountCalculator.init
  end
  
end

RSpec.configuration.include SeedHelper, :type => :feature
