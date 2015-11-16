module CampaignHelper
  def find_section(name)
    find '#' + name.downcase.gsub(' ', '_')
  end

  def add_module(section_title, add_text)
    within find_section(section_title) do
      all('.module').count
      click_link add_text
      wait_for_ajax
      within first('.module:last-child') do
        yield if block_given?
      end
    end
  end
  
  def create_campaign(opts = {})
    opts = { 
      :name => 'test campaign', 
      :description => 'test description'
    }.merge(opts)
    click_links 'Admin', 'Campaigns', 'Create new campaign'
    fill_in 'Name', :with => opts[:name]
    select 'Core', from: 'Pillar'
    fill_in 'Description', :with => opts[:description]
    click_button 'Create campaign'
  end
  
  def add_page_sequence(opts = {})
    opts = { 
      :name => 'test page sequence', 
      :facebook_image_url => 'http://localhost/images/getup_logo.png'
    }.merge(opts)
    click_link 'Add a page sequence'
    fill_in 'Name', :with => opts[:name]
    select 'Default', :from => 'Theme'
    fill_in 'Facebook Image URL', :with => opts[:facebook_image_url]
    click_button 'Create page sequence'
  end
  
  def add_page(opts = {})
    opts = { :title => 'test title' }.merge(opts)
    click_link 'Add a page'
    fill_in 'Page Title', :with => opts[:title]
    click_button 'Create page'
    add_module 'Main Content', 'Add HTML' do
      fill_in_code_mirror 'test description'
    end
    yield if block_given?
    click_button 'Save page'

    if opts[:tags]
      # not sure why this fails
      # within('.acts-as-taggable-on') do
      #   find('input').set opts[:tags]
      # end
      # click_link 'Unlock Sorting' # trigger tag commit
      p = Page.last
      p.tag_list.add(*opts[:tags])
      p.save!
    end
  end
  
  def send_campaign_email(opts = {})
    opts = { :campaign => 'test campaign', :subject => 'test campaign subject' }.merge(opts)
    
    campaign_url = URI.join(current_url, first('a', :text => 'Show Public View')['href']).to_s
    campaign_url += "?#{opts[:params].to_param}" if opts[:params]
    
    # add a push
    click_link opts[:campaign]
    click_link 'Add a push'
    fill_in 'Name', :with => 'test push'
    click_button 'Create push'
    
    # add a blast
    click_link 'Add a blast'
    fill_in 'Name', :with => 'test blast'
    click_button 'Create blast'
    
    # cut a list
    click_link 'Cut a list'
    first('.remove-filter').click # remove default electorate rule
    show_count_and_save
    
    # Add an email message
    click_link 'Add an email'
    fill_in 'Name', :with => 'test email'
    fill_in 'Subject', :with => opts[:subject]
    fill_in_code_mirror "<a href=\"#{campaign_url}\">help my test campaign</a>"
    fill_in 'Recipients', :with => 'phil@proof.com'
    yield if block_given?
    click_button 'Send Proof'
    # send email to members
    click_button 'Send'
    work_off_new_mail
  end
  
  def visit_campaign_in_email(email, link_text)
    visit campaign_in_email(email, link_text)
  end

  def campaign_in_email(email, link_text)
    # Duncan:
    # hack around fact that sendgrid does bulk sending substitution logic from header directives
    sendgrid_to = JSON.parse(current_email.header['X-SMTPAPI'].value)['to']
    sendgrid_subs = JSON.parse(current_email.header['X-SMTPAPI'].value)['sub']
    email_body = current_email.default_part_body.to_s
    raise "campaign email was not delivered to #{email}" unless sendgrid_to.index(email)
    sendgrid_subs.each do |token, subs|
      email_body.gsub! token, subs[sendgrid_to.index email]
    end
    
    %r{<a[^>]*href=['"]?([^'"]*)['"]?[^>]*?>[^<]*?#{link_text}[^<]*?</a>}.match(email_body)[1]
  end
  
  def add_tags(tags)
    fill_in_tags "Tags", :with => tags
    # hack for build server ???
    first("#add-tags input[type=submit]").click until first("#add-tags input[type=submit]").blank?
  end
  
  def show_count_and_save
    click_button 'Show count'
    page.execute_script(%{$('#listForm').append('<input type="button" id="save-list" value="Save">');})
    click_button 'Save'
    work_off
  end
end
RSpec.configuration.include CampaignHelper, :type => :feature 
