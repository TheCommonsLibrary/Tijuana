module NationBuilderHelper
  PATHS = {
    :admin => "/admin",
    :tags => "/admin/signup_tags/new",
    :lists => "/admin/custom_lists"
  }
  
  def nb_page(name)
    "https://getupstaging.nationbuilder.com" + PATHS[name]
  end
  
  def nb_sign_in_as_admin(opts = {})
    opts = { :email => 'tech@getup.org.au', :password => 'Z%LQGnE8XdJzfd5NjawgkC3Skoobz5' }.merge opts
    ignore_js_errors{ visit nb_page(:admin) }
    fill_in 'Email Address', :with => opts[:email], :match => :first
    fill_in 'Password', :with => opts[:password]
    click_button 'Sign in with email'
    wait_for_ajax
  end

  def nb_search(email)
    fill_in 'search_box', :with => email
    press_enter find('#search_box')
    wait_until(10) { first("#search-toolbar-wrapper") }
  end

  def nb_tag_search(tag)
    ignore_js_errors{ visit nb_page(:tags) }
    fill_in "search", :with => tag
    press_enter find('#search')
  end
  
  def replay_person_update(bin_name, email)
    begin
      webhook_data = Requestbin::Bins.requests(bin_name).detect { |r| r["body"].include?(email) }['body']
    rescue => e
      raise 'RequestBin failed'
    end
    uri = URI "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}/webhooks/person_changed/#{NATION_BUILDER[:webhooks_token]}"
    req = Net::HTTP::Post.new uri, initheader = {'Content-Type' =>'application/json'}
    req.body = webhook_data
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request req
    end

    work_off
  end
  
  def enable_nb_sync(&block)
    AppConstants.stub(:nationbuilder_sync_user_after_save).and_return(true)
    bin_name = Requestbin::Bins.create["name"]
    bin_webhook = NationBuilder::Api.call_api :webhooks, :create, :webhook => { "url" => "http://requestb.in/#{bin_name}", "event" => "person_update", "version" => 4 }
    begin
      yield bin_name
    ensure
      NationBuilder::Api.call_api :webhooks, :destroy, :id => bin_webhook["id"] if bin_webhook && bin_webhook["id"].present?
    end
  end

  def clean_up_tags(*tags)
    tags.each do |tag|
      nb_tag_search tag
      find('.icon-pencil').click
      click_link "Delete Tag"
      dismiss_dialog
      sleep 1 # if we don't pause slightly, the tag won't be deleted
    end
  end
end

RSpec.configuration.include NationBuilderHelper, :type => :feature
