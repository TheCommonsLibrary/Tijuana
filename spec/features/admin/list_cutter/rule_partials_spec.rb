require 'spec_helper'

describe 'rule partials', :driver => :rack_test do
  class RuleTestingController < ApplicationController
    attr_accessor :rule
    helper_method :rule
    
    def show
      self.rule = "list_cutter/#{params[:rule_slug]}".camelize.constantize.new params[:rule] || {}
      render :inline => %{
        <%= form_for :rule, :method => :put do |f| %>
          <%= render :partial => "admin/list_cutter/rules/" + rule.class.code, :locals => { :key => rule.class.code, :f => f } %>
          <%= f.submit 'Save' %>
        <% end %>
      }, :layout => false
    end
  end
  
  before do
    Rails.application.routes.draw do
      match ':rule_slug' => "rule_testing#show", :via => :get
      match ':rule_slug' => "rule_testing#show", :via => :put
    end
  end
  
  after do
    Rails.application.reload_routes!
  end
  
  describe 'should post, render, and setup fields correctly' do
    it 'action taken' do
      visit '/action_taken_rule'
      fill_in 'rule_greater_than', :with => '3'
      fill_in 'rule_page_ids', :with => '4,5,6'
      click_button 'Save'
      
      page.should have_field 'rule_greater_than', :with => '3'
      page.should have_field 'rule_page_ids', :with => '4,5,6'
    end
    
    it 'agra role' do
      visit '/agra_role_rule'
      select 'creator', :from => 'rule_role'
      click_button 'Save'
      
      page.should have_select 'rule_role', :selected => ['creator']
    end
    
    it 'agra slug' do
      visit '/agra_slug_rule'
      fill_in 'rule_slug', :with => 'my-cool-petition'
      click_button 'Save'
      
      page.should have_field 'rule_slug', :with => 'my-cool-petition'
    end
    
    it 'campaign rule' do
      Campaign.stub(:select_options).and_return [['Budget', '1'], ['Reef', '2']]
      visit '/campaign_rule'
      select 'Reef', :from => 'rule_campaigns'
      click_button 'Save'
      
      page.should have_select 'rule_campaigns', :selected => ['Reef']
    end
    
    it 'country rule' do
      visit '/country_rule'
      select 'BRAZIL', :from => 'rule_country_iso'
      click_button 'Save'
      
      page.should have_select 'rule_country_iso', :selected => ['BRAZIL']
    end
    
    it 'custom sql' do
      visit '/custom_sql_rule'
      fill_in 'rule_custom_sql', :with => "select id from users where first_name = 'Fred'"
      click_button 'Save'
      
      page.should have_field 'rule_custom_sql', :with => "select id from users where first_name = 'Fred'"
    end
    
    it 'donor rule' do
      visit '/donor_rule'
      select 'One Off', :from => 'rule_frequencies'
      select 'Donate Weekly', :from => 'rule_frequencies'
      fill_in 'rule_campaign_ids', :with => '1,2,3'
      fill_in 'rule_page_ids', :with => '4,5,6'
      choose 'currently active donors'
      click_button 'Save'
    
      page.should have_select 'rule_frequencies', :selected => ['One Off', 'Donate Weekly']
      page.should have_field 'rule_campaign_ids', :with => '1,2,3'
      page.should have_field 'rule_page_ids', :with => '4,5,6'
      page.should have_checked_field 'currently active donors'
    end
    
    it 'electorate rule' do
      RuleTestingController.send(:define_method, :federal_electorates) { [['Camperdown', 1], ['Newtown', 2]] }
      RuleTestingController.helper_method(:federal_electorates)
      visit '/electorate_rule'
      select 'Camperdown', :from => 'rule_electorate_ids'
      click_button 'Save'
      
      page.should have_select 'rule_electorate_ids', :selected => ['Camperdown']
    end
    
    it 'email action rule' do
      visit '/email_action_rule'
      select 'Clicked', :from => 'rule_action'
      fill_in 'rule_email_id', :with => '3'
      click_button 'Save'
      
      page.should have_select 'rule_action', :selected => ['Clicked']
      page.should have_field 'rule_email_id', :with => '3'
    end
    
    it 'email address rule' do
      visit '/email_addresses_rule'
      fill_in 'rule_email_addresses_string', :with => 'duncan@getup.org.au, james@getup.org.au'
      click_button 'Save'
      
      page.should have_field 'rule_email_addresses_string', :with => 'duncan@getup.org.au, james@getup.org.au'
    end
    
    it 'email domain rule' do
      visit '/email_domain_rule'
      fill_in 'rule_domain', :with => 'gmail.com'
      click_button 'Save'
      
      page.should have_field 'rule_domain', :with => 'gmail.com'
    end
    
    it 'email frequency rule' do
      visit '/email_frequency_rule'
      fill_in 'rule_email_frequency', :with => '3'
      fill_in 'rule_time_period', :with => '7'
      click_button 'Save'
      
      page.should have_field 'rule_email_frequency', :with => '3'
      page.should have_field 'rule_time_period', :with => '7'
    end
    
    it 'member value money' do
      visit '/member_value_money_rule'
      select '$101 - $500', :from => 'rule_value_range'
      fill_in 'rule_lower_limit', :with => '$101'
      fill_in 'rule_upper_limit', :with => '$500'
      fill_in 'rule_time_limit_months', :with => '12'
      click_button 'Save'
      
      page.should have_select 'rule_value_range', :selected => ['$101 - $500']
      page.should have_field 'rule_lower_limit', :with => '$101'
      page.should have_field 'rule_upper_limit', :with => '$500'
      page.should have_field 'rule_time_limit_months', :with => '12'
    end
    
    it 'postcode within' do
      RuleTestingController.send(:define_method, :postcode_options) { [['2034', 1], ['2050', 2]] }
      RuleTestingController.helper_method(:postcode_options)
      visit '/postcode_within_rule'
      select '2050', :from => 'rule_postcode_ids'
      fill_in 'rule_within', :with => '5'
      click_button 'Save'
      
      page.should have_select 'rule_postcode_ids', :selected => ['2050']
      page.should have_field 'rule_within', :with => '5'
    end
    
    it 'state territory rule' do
      Jurisdiction.stub(:select_options_for_states).and_return [['New South Wales', 'NSW'], ['Queensland', 'QLD']]
      visit '/state_territory_rule'
      select 'New South Wales', :from => 'rule_states_territories'
      check 'rule_no_state'
      click_button 'Save'
      
      page.should have_select 'rule_states_territories', :selected => ['New South Wales']
      page.should have_checked_field 'rule_no_state'
    end
    
    it 'old tagged users rule' do
      visit '/old_tagged_users_rule'
      fill_in 'rule_old_tags', :with => 'volunteer, rsvp'
      click_button 'Save'
      
      page.should have_field 'rule_old_tags', :with => 'volunteer, rsvp'
    end
    
    it 'tokens rules' do
      visit '/tokens_rule'
      fill_in 'rule_tokens_string', :with => 'FHJD112, YDFBSD22'
      click_button 'Save'
      
      page.should have_field 'rule_tokens_string', :with => 'FHJD112, YDFBSD22'
    end
  end
end
