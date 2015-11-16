require_relative "scenario_helper"

xdescribe "campaigner tags members for followup", :type => :feature, :js => true do
  specify do
    begin
      end_of_tag = "sync" # to turn off nb syncing, change to "blah"
      
      seed
      
      # we need unique email addresses for nation builder integration (sorry)
      token = SecureRandom.hex 6
      cate_community = create :user_for_nation_builder, :first_name => "Cate", :last_name => "Community#{token}", :email => "cate#{token}@example.com"
      owen_organiser = create :user_for_nation_builder, :first_name => "Owen", :last_name => "Organiser#{token}", :email => "owen#{token}@example.com"
      
      enable_nb_sync do |bin_name|
        # campaigner updates user and includes sync tag
        sign_in_as_admin :email => "admin@admin.com"
        click_links "Admin", "Users", cate_community.full_name
        fill_in_tags "Tags", :with => "valuable_member_#{token}_#{end_of_tag}"
        click_button "Save user"
        work_off

        if end_of_tag == "sync"
          # campaigner updates mobile in nation builder
          nb_sign_in_as_admin
          save_and_open_page
          nb_search cate_community.email
          click_link "Edit"
          fill_in "Mobile number", :with => '0408123456'
          click_button "Save person"

          # replay webhook
          replay_person_update bin_name, cate_community.email
    
          # campaigner checks that mobile updated in Tijuana
          visit "/admin"
          click_links "Admin", "Users", cate_community.full_name
          page.should have_field 'Mobile Number', with: '0408123456'
        end
    
        end_of_tag = "sync"
        
        # campaigner cuts a list and mass tags members
        visit "/admin"
        click_link "Users"
        click_link "Cut a list to record actions / tag"
        all("select.filter-by").last.select "Email Address List"
        find("textarea", :match => :first).set [cate_community.email, owen_organiser.email].join("\n")
        click_button "Show count"
        work_off
        add_tags "mass_tag_#{token}_#{end_of_tag}"
        work_off

        if end_of_tag == "sync"
          # campaigner checks members are tagged in nation builder
          nb_tag_search "mass_tag_#{token}_sync"
          click_link "mass_tag_#{token}_sync"
          page.should have_content cate_community.full_name
          page.should have_content owen_organiser.full_name
        
          # campaigner is happy that no garbage lists are remaining in nation builder
          Timecop.travel 2.hours.from_now do
            work_off
            visit nb_page(:lists)
            page.should have_no_content "mass_tag_#{token}_sync"
          end

          clean_up_tags "mass_tag_#{token}_sync", "valuable_member_#{token}_sync"
        end
      end
    rescue => e
      if e.message == 'RequestBin failed'
        puts "'#{self.class.description}' - skipped because request bin is down."
      else 
        raise e
      end
    end
  end
end
