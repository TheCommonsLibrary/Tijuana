module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))
    
 
    when /the dashboard/
      '/dashboard'

    when /My GetUp!/
      '/dashboard'

    when /the unsubscribe me page/
      unsubscribe_path

    when /the new list page/
      admin_list_cutter_new_path

    when /the admin campaign page for "(.*?)"/
      admin_campaign_path(Campaign.find_last_by_name($1), {:bare => nil})
      
    when /the public campaign page entitled "(.*?)"/
      page = Page.find_last_by_name($1)
      page.should_not be_nil
      page_path(page)
      
    when /the admin page sequence page for "(.*?)"/
     admin_page_sequence_path(PageSequence.find_last_by_name($1), {:bare => nil})      

    when /the content editing page for "(.*?)"/
      page = Page.find_last_by_name($1)
      page.should_not be_nil
      edit_admin_page_path(page)
      
    when /the admin push page for "(.*?)"/
      push = Push.find_last_by_name($1)
      push.should_not be_nil
      admin_push_path(push)
      
    when /the public static page "(.*)\/(.*)"/
      page_sequence_name, page_name = $1, $2
      page = Page.find(:last, :conditions => ['lower(name) = ?', $2.downcase])
      page.should_not be_nil
      page.page_sequence.name.downcase.should == page_sequence_name
      "/#{page.page_sequence.name.downcase}/#{page.name.downcase}"
      
    when /the edit admin user page for "(.*?)"/
      user = wait_until(10) { User.find_by_email($1) }
      user.should_not be_nil
      edit_admin_user_path(user, {:bare=>nil})

    when /the edit admin donation page/
      donation = Donation.new
      edit_admin_donation_page(donation)

    when /the page with URL "(.*)"/
      $1

    when /the Get Togethers page/
      "/get_togethers"

    when /the admin get together page for "(.*)"/
      get_together = GetTogether.find_by_name($1)
      admin_get_together_path(get_together.id, {:bare => nil})

    when /the "(.*)" event page/
      event = Event.find_by_name($1)
      event_path(event.friendly_id, {:bare => nil})

    when /the "(.*)" get together page/ 
      get_together = GetTogether.find_by_name($1)
      get_together_path(get_together.id, {:bare => nil})

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
