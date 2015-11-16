require 'csv'
require_relative '../../scenarios/support/electoral_seeder'

Given /^I have a sample set of users$/ do
  i = 0;
  20.times do
    i = i+1
    User.create(:id => i, :email => "getup#{i}@getup.org.au", :first_name => "first_name#{i}", :last_name => "last_name#{i}", :is_member => false)
  end
  20.times do
    i = i+1
    User.create(:id => i, :email => "moo#{i+20}@homes.com", :first_name => "first_cup#{i+20}", :last_name => "last_name#{i+20}", :is_admin => true, :is_member => true)
  end
  20.times do
    i = i+1
    User.create(:id => i, :email => "temp#{i+40}@imthepmbtch.gov.au", :first_name => "first_name#{i+40}", :last_name => "last_angel#{i+40}", :is_member => true)
  end
  i = i+1
  User.create(:id => i, :email => "chrisanthemum@example.com", :first_name => "Chris", :last_name => "Anthemum", :is_member => true)
end

Given /^I run the seed task$/ do

  table_to_clear = [Party, Electorate, Region, Mp, Senator, Jurisdiction, Postcode]

  for table in table_to_clear
    table.delete_all
  end

  User.create email: 'info+shared_connection@getup.org.au', is_admin: true, is_member: true

  theme = Theme.create!(:name => "application", :display_name => "Default", :id => 1)
  Theme.create!(:name => "Happy", :display_name => "Happy", :id => 2)
  Theme.create!(:name => "Sad", :display_name => "Sad", :id => 3)

  # STATIC PAGES
  ["About", "Community", "Campaigns", "Donate", "Membership"].each do |page_sequence_name|
    ps = PageSequence.create!(:name => page_sequence_name, :theme => theme, facebook_image: 'http://fb.png')
    ps.pages.create!(:name => "First Page Name")
  end
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

  # SAMPLE CAMPAIGNS AND PAGES
  climate, wikileaks, walrus, forestry, same_sex_marriage = Campaign.create!([
    {:name => 'Climate', :description => 'Lorem ipsum dolor sit amet.', accounts_key: 'Environment'},
    {:name => 'Wikileaks', :description => 'Lorem ipsum dolor sit amet.', accounts_key: 'Democracy'},
    {:name => 'Walruses', :description => 'Lorem ipsum dolor sit amet.', accounts_key: 'Environment'},
    {:name => 'Forestry', :description => 'Lorem ipsum dolor sit amet.', accounts_key: 'Environment'},
    {:name => 'Same Sex Marriage', :description => 'Lorem ipsum dolor sit amet.', accounts_key: 'Human Rights'}
  ])

  PageSequence.create!([
    {:name => 'Gunns Petition', :campaign => forestry, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'Climate Donation', :campaign => climate, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'Wikileaks Email', :campaign => wikileaks, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'Walrus MP Email', :campaign => walrus, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'Walrus MP Email with delay', :campaign => walrus, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'Walrus MP Call', :campaign => walrus, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'Blank Slate', :campaign => climate, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'LGBT Petition', :campaign => same_sex_marriage, :theme => theme, facebook_image: 'http://fb.png'},
    {:name => 'Static Page Sequence', :theme => theme, facebook_image: 'http://fb.png'}
  ])

  PageSequence.all.each do |ps|
    Page.create!([
      {:name => "Landing Page for #{ps.name}", :page_sequence => ps, :position => 1},
      {:name => "Thankyou Page for #{ps.name}", :page_sequence => ps, :position => 2}
    ])
  end

  # SAMPLE GET TOGETHER
  required_user_details = {
          first_name: :optional,
          last_name: :optional,
          mobile_number: :optional,
          home_number: :optional,
          street_address: :optional,
          suburb: :optional,
          postcode_number: :optional,
          country_iso: :hidden
      }
  get_together = GetTogether.create!(:name => "Adopt a kitten GetTogether", :required_user_details => required_user_details, :description=> "Let us save teh cuteness!", :campaign => forestry, :from_date =>Date.today, :to_date=> Date.today + 2, :content_module => HtmlModule.create!(:content => "uau!"), :from_time => 100, :to_time => 2300, :recommended_date => Date.tomorrow, :theme_id => 1)

  # SAMPLE EVENT
  host = User.create!(:email => "the-happy-kitten-event@getup.org.au", :first_name => "love", :last_name => "kittens",
                      :is_member => true)
  Event.create!(:name => "The Happy Kitten Event", :get_together => get_together, :host => host, :date => Date.today, :address_latitude => -33.867487, 
                :address_longitude => 151.206990, :time => 700, :address => 'Somewhere in time', :confirmed_at => Time.now, :capacity => 1, 
                :terms_and_conditions => true)

  attendee = User.create(:email => "attendee@event.com", :first_name => "the", :last_name => "attendee", :is_member => true)
  Event.create!(:name => "Full Event", :get_together => get_together, :host => host, :date => Date.today, :address_latitude => -33.867487, 
                :address_longitude => 151.206990, :time => 700, :address => 'Somewhere in time', :confirmed_at => Time.now, 
                :capacity => 1, :attendees=>[attendee], :terms_and_conditions => true)


  # GUNNS PETITION
  page = Page.find_by_name("Landing Page for Gunns Petition") or raise 'Page not found'
  kittens = HtmlModule.create!(:content => "Save the kittens!")
  ContentModuleLink.create!(:page => page, :content_module => kittens, :position => 1, :layout_container => :main_content)
  walrus = HtmlModule.create!(:content => "No, save the walrus!")
  ContentModuleLink.create!(:page => page, :content_module => walrus, :position => 2, :layout_container => :main_content)

  getup_info = DirectLandingHtmlModule.create!(:content => "I know you did not directly land from email, so I give you some information about what GetUp do")
  ContentModuleLink.create!(:page => page, :content_module => getup_info, :position => 3, :layout_container => :main_content)

  petition = PetitionModule.create!(
    :title => "Sign, please",
    :content => 'We the undersigned...',
    :petition_statement => "This is the petition statement",
    :signatures_target => 0,
    :thermometer_threshold => 0
  )
  ContentModuleLink.create!(:page => page, :content_module => petition, :position => 3, :layout_container => :main_content)

  page.update_attributes(
    :thankyou_email_text => 'Dear friend, \n\nthanks.',
    :thankyou_email_subject => "Thanks for taking action.",
    :required_user_details => {:first_name=>:required, :last_name=>:optional}
  )

  page = Page.find_by_name("Thankyou Page for Gunns Petition") or raise 'Page not found'
  narwhal = HtmlModule.create!(:content => "What about Narwhals?")
  ContentModuleLink.create!(:page => page, :content_module => narwhal, :position => 1, :layout_container => :main_content)
  ducks = HtmlModule.create!(:content => "Ducks are cool too!")
  ContentModuleLink.create!(:page => page, :content_module => ducks, :position => 2, :layout_container => :main_content)


  # CLIMATE DONATION
  page = Page.find_by_name("Landing Page for Climate Donation") or raise 'Page not found'
  donation = DonationModule.create!(
    :title => "We need cash!",
    :content => "Please give generously.",
    :thermometer_threshold => 1000,
    :personalised_amounts => "",
    :personalised_default_amount => "",
    eligible_for_personalised_donation_tests: false,
    :frequency_options=>{"one_off"=>"default", "weekly"=>"optional", "monthly"=>"hidden", "annual"=>"hidden"}
  )
  ContentModuleLink.create!(:page => page, :content_module => donation, :position => 1, :layout_container => :sidebar)

  # WIKILEAKS EMAILS
  page = Page.find_by_name("Landing Page for Wikileaks Email") or raise 'Page not found!'
  page.send_thankyou_email = false
  page.save!
  email_targets = EmailTargetsModule.create!(
    :title => "Email the PM",
    :content => "You aren't listening Julia, and we're not happy",
    :default_subject => "Dear Joolia",
    :default_body => "Hi, I've got to put it out there, I'm not happy with you right now.",
    :target_emails => "colonelbobson@heroes.com, jooolia@imthepm.gov.au",
    :display_defaults => '1',
    :cc_me => '1',
    :button_text => "SEND SEND SEND!"
  )
  ContentModuleLink.create!(:page => page, :content_module => email_targets, :position => 1, :layout_container => :sidebar)

  # WALRUS PLIGHT EMAIL MP
  page = Page.find_by_name("Landing Page for Walrus MP Email") or raise 'Page not found!'
  page.send_thankyou_email = false
  page.save!
  emp = EmailMPModule.create!(
    :title => "Email your Labor MP",
    :content => "Make them tackle the old rock dude with the bald head.",
    :default_subject => "Dear my Labor representative",
    :default_body => "Hi, please tell PG that he needs to be on the ball with the plight of the walruses.",
    :display_defaults => '1',
    :target_senate => '1',
    :button_text => "WALRUS!"
  )
  emp.target_party_ids = {'2' => '1'}
  emp.save!
  ContentModuleLink.create!(:page => page, :content_module => emp, :position => 1, :layout_container => :sidebar)



  # WALRUS PLIGHT CALL MP
  page = Page.find_by_name("Landing Page for Walrus MP Call") or raise 'Page not found!'
  page.send_thankyou_email = false
  page.save!
  emp = CallMPModule.create!(
    :title => "Call your Labor MP",
    :content => "Make them tackle the old rock dude with the bald head.",
    :display_defaults => '1',
    :target_senate => '1',
    :button_text => "I called!"
  )
  emp.target_party_ids = {'2' => '1'}
  emp.save!
  ContentModuleLink.create!(:page => page, :content_module => emp, :position => 1, :layout_container => :sidebar)

  # SAME SEX MARRIAGE USER DETAILS COLLECTION
  page = Page.find_by_name("Landing Page for LGBT Petition") or raise 'Page not found'
  frogs = HtmlModule.create!(:content => "Save the frogs!")
  ContentModuleLink.create!(:page => page, :content_module => frogs, :position => 1, :layout_container => :main_content)
  toads = HtmlModule.create!(:content => "No, save the toads!")
  ContentModuleLink.create!(:page => page, :content_module => toads, :position => 2, :layout_container => :main_content)
  petition = PetitionModule.create!(
    :title => "Sign, please",
    :content => 'We the undersigned...',
    :petition_statement => "This is the petition statement",
    :signatures_target => 0,
    :thermometer_threshold => 0
  )
  ContentModuleLink.create!(:page => page, :content_module => petition, :position => 3, :layout_container => :main_content)

  page.update_attributes(:required_user_details => {:first_name=>:required, :last_name=>:refresh, :postcode => :optional, :suburb => :required})

  ElectoralSeeder.seed_electoral_data

  MemberCountCalculator.init

  # Creates the Umbrella User.
  # It's used for offline donations when a user (1) doesn't exist in our database AND (2) doesn't have an email address
  User.create(:first_name => "Umbrella", :last_name => "User", :email => 'offlinedonations@getup.org.au')


end
