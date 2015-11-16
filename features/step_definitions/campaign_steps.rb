Given /^I have a campaign named "([^\"]*)"$/ do |name|
  @campaign = Campaign.find_or_create_by_name_and_accounts_key(name, 'Core')
end

Given /^I visit the "([^"]*)" campaign page$/ do |name|
  campaign = Campaign.find_by_name(name)
  campaign.should_not be_nil
  visit admin_campaign_path(campaign, {:bare => nil})
end

Given /^a campaign page "([^"]*)"$/ do |page_name|
  page = Page.find_by_name(page_name)
  page = create(:page_with_parent, :name => page_name) if page.nil?
  visit edit_admin_page_path(page)
end

Given /^there is an email "([^"]*)" for the "([^"]*)" campaign$/ do |email_name, campaign_name|
  campaign = Campaign.find_by_name(campaign_name)
  campaign.should_not be_nil
  
  push = create(:push, :campaign => campaign, :name => "Push for #{email_name}")
  # push.create_activities_table
  
  blast = create(:blast, :push => push, :name => "Blast for #{email_name}")
  email = create(:email, {:blast => blast, :name => email_name, :from_address => "test@getup.com.au", :reply_to_address => "test@getup.com.au", :subject => "test email", :body => "This is a test"}) 
end

Given /^there is a push "([^"]*)" for the "([^"]*)" campaign$/ do |push_name, campaign_name|
  campaign = Campaign.find_by_name(campaign_name)
  campaign.should_not be_nil
  
  push = create(:push, :campaign => campaign, :name => push_name)
  # push.create_activities_table
end

Given /^there is a blast "([^"]*)" for the "([^"]*)" push$/ do |blast_name, push_name|
  push = Push.find_by_name(push_name)
  push.should_not be_nil
  blast = create(:blast, :push => push, :name => blast_name)  
end

Given /^there is a blast "([^"]*)" with a non-filtering list for the "([^"]*)" push$/ do |blast_name, push_name|
  push = Push.find_by_name(push_name)
  push.should_not be_nil
  # push.create_activities_table
  list = List.create!
  blast = create(:blast, :push => push, :list => list, :name => blast_name)  
end

Given /^there is an email "([^"]*)" for the "([^"]*)" blast$/ do |email_name, blast_name|
  blast = Blast.find_by_name(blast_name)
  email = create(:email, {:blast => blast, :name => email_name, :from_address => "test@getup.com.au", :reply_to_address => "test@getup.com.au", :subject => "test email", :body => "This is a test", :footer => "getup"})
end

Given /^there are (\d+) members in the system$/ do |member_count|
  member_count.to_i.times do |n|
    if User.count < member_count.to_i 
      create(:user, :email => "user_#{n}@example.com")
    end
  end
end

Given /^a proof has been sent for "([^"]*)"$/ do |email_name|
  email = Email.find_by_name(email_name)
  email.should_not be_nil
  email.send_test!
end

Given /^"([^"]*)" has been delivered to (\d+) members$/ do |email_name, member_count|
  email = Email.find_by_name(email_name)
  email.should_not be_nil
  job = BlastJob.new({
                   :no_jobs => 1,
                   :current_job_id => 0,
                   :list => email.blast.list,
                   :email => email,
                   :limit => 5
               })
  job.perform
end
