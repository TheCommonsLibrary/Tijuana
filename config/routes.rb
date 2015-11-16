require_relative '../app/models/cloaked_domain'

Tijuana::Application.routes.draw do

  if ['development', 'test'].include? Rails.env
    mount JasmineRails::Engine => '/specs'
    mount JasmineFixtureServer => '/spec/javascripts/fixtures'
  end

  devise_for :users
  devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
  end

  # Vanity Routes
  post '/vanity/add_participant'
  match '/admin/vanity(/:action(/:id(.:format)))', :controller => :vanity, :via => [:get, :post]

  namespace :admin do
    root :to => "dashboard#index"

    get 'dashboard' => 'dashboard#index', :as => "dashboard"
    get 'dashboard/latest_emails' => 'dashboard#latest_emails', :as => 'latest_emails'

    scope '(:bare)', :bare => /bare/ do

      resources :campaigns do
        member do
          get :ask_stats_report
        end
      end

      resources :page_sequences do
        member do
          put :sort_pages
          get :duplicate
        end
      end

      resources :get_togethers do
        member do
          get :events
        end
      end

      resources :users do
        collection do
          get :tag
          post :add_tags
          post :add_external_actions
          post :create_page_add_external_actions
          get :show_import
          post :import
          get :download_template_file
          get :download_country_iso_file
        end
        member do
          get :transactions
          get :transaction_report
        end
      end
    end

    resources :pages do
      member do
        post :add_tag
        post :remove_tag
        get :add_content_module
        get :remove_content_module
        put :sort_content_modules
        put :switch_container
        get :bookmark_content_module
        get :unbookmark_content_module
        get :show_bookmarks
        get :add_from_bookmarks
        get :unlink_content_module
        get :validate_html
      end
      resources :acquisition_sources
    end

    resources :pushes do
      member do
        get :email_stats_report
        get :stats
        post :notes
        post :deliver_multiblast
        post :cancel_multiblast
        post :duplicate
      end
    end
    resources :blasts do
      member do
        post :deliver
        post :cancel
      end
    end
    resources :emails do
      collection do
        post :create_subject_line_test
      end
    end

    resource :homepage
    resources :static_pages
    resources :redirects
    resources :images
    resources :mps
    resources :senators
    resources :downloadable_assets
    
    resource :payments do
      member do
        put :set_blocked_ips
        put :set_fraud_guard
        put :set_emergency_paypal
        put :set_gateway1_percentage
      end
    end

    resources :merges do
      collection do
        get :whitelist
        put :update_whitelist
      end
    end

    resource :quarantines do
      collection do
        put :update_cr_slugs
      end
    end

    resource :daisy_chains do
      collection do
        put :switch
      end
    end

    resources :donations do
      member do
        patch :cancel_recurring
        put :assign_flagged_donation
        put :update_offline_donation
        get :edit_offline_donation
        put :update_oneoff_donation
        get :edit_oneoff_donation
        patch :update_credit_card_identifiers
      end
      collection do
        get 'flagged'
        put 'dismiss_recurring_donations'
        put 'dismiss_failed_new_donations'
      end
    end

    resources :transactions do
      member do
        put :refund
      end
    end

    get  "list_cutter/new"
    get  "list_cutter/edit"
    get  "list_cutter/poll"
    post "list_cutter/count"
    put  "list_cutter/update"

    # Raise error route, for testing exception notification in different environments
    get 'raise_error/blowup'

    get 'donations/:id/assign_flagged_donation' => 'donations#assign_flagged_donation'

    get 'link_shortener/generate_shortened_url'
  end # ADMIN NAMESPACE

  resources :donations, :only => :update

  resource :user, :only => :update
  resources :users do
    collection do
      get :lookup
      get :address
      get :full_address
      post :make_recurring
      post :setup_quickdonate
      post :logout_quickdonate
      get :user_email_story
      post :not_you
    end
  end

  resources :radios do
    collection do
      get :lookup
    end
  end

  match "/mps/lookup", to: 'mps#lookup', via: :options
  match "/mps/ensure_in_target_party", to: 'mps#ensure_in_target_party', via: :options
  match "/mps/select_senator", to: 'mps#select_senator', via: :options
  match "/mps/party_options", to: 'mps#party_options', via: :options

  resources :mps do
    collection do
      get :lookup
      get :ensure_in_target_party
      get :select_senator
      get :party_options
    end
  end

  resources :events do
    collection do
      get :confirm
    end
    member do
      post  :cancel
      post  :attend
      post  :cancel_attendance
      post  :message_attendees
      post   :confirm
    end
    resources :comments, :module => "events" do
      member do
        post :reply
      end
    end
  end

  get '/activity' => 'activity#show'

  get '/ozvote' => 'ozvote#index'
  get '/vote/:electorate' => 'ozvote#vote'

  resources :get_togethers
  resources :polling_booths
  match "polling_booths.json", to: 'polling_booths#index', via: :options
  get '/electionscorecards2013data/layout_for_dev' => 'scorecards#layout_for_dev'
  get '/scorecard2013' => 'scorecards#national'
  get '/electionscorecards2013data' => 'scorecards#index'

  # My GetUp! dashboard
  get '/dashboard' => 'dashboard#index'
  get '/dashboard/donation-history' => 'dashboard#donation_history'
  get '/dashboard/donation-history-header' => 'dashboard#donation_history_header', :as => "invoice_header"
  get '/dashboard/update-card/:id' => 'dashboard#update_card', :as =>'dashboard_update_card'
  post '/dashboard/cancel_event_attendee/:id' => 'dashboard#cancel_event_attendee', :as =>'dashboard_cancel_event_attendee'

  # Generic event tracking pixel
  get '/event/:t/beacon.gif' => "beacon#track_event"
  # User email tracking gif
  get '/emailer/:t/beacon.gif' => "beacon#track_email_target"
  #Email tracking gif
  get '/beacon.gif' => "beacon#index"

  # Unsubscribe user
  get "unsubscribe" => "unsubscribe#new"
  post "unsubscribe/create"

  # Become a member from homepage
  post "become_a_member" => "home#subscribe"

  # robots.txt
  get '/robots.:format' => 'home#robots'

  # Paypal IPN callback
  post "paypal/ipn/:id" => "paypal#ipn"

  # Doorknocking
  get "/modules/:module_id/streets" => "modules#streets", as: 'module_streets'

  #Route to the API
  post "/api/users" => "api#users"
  get '/api/vision_survey_2014' => 'api#vision_survey_2014'
  get "/api/csg_petition_signature_count" => "api#csg_petition_signature_count"
  post "/api/take_action_with_fb" => "api#take_action_with_fb"
  post "/api/tag_emails" => "api#tag_emails"
  get "/api/pillared_page_sequences/:pillar" => "api#page_sequences"
  get "/api/transparency_stats" => "api#transparency_stats"
  post "/api/electoral_target" => "api#electoral_target"

  post "/testimonial/record_action" => "testimonial#record_action"

  # NationBuilder webhooks
  post "/webhooks/person_changed/:webhooks_token" => "nation_builder_webhooks#person_changed"

  # webhook for CommunityShapers' dialer (Noojee)
  post "/webhooks/call_outcome/:token" => "webhooks#call_outcome"

  if Rails.env.development?
    mount MailPreview => 'mail_view'
  end

  # redundant for routing purposes, but needed for path/url view helpers (also matches static pages)
  match "/:page_sequence_id(/:id)" => "pages#show", :as => "cloaked", :via => [:get, :post, :put]

  # friendly_id URLs for all campaign/static pages (see above route too)
  match "(/campaigns/:campaign_id)/:page_sequence_id(/:id)" => "pages#show", :as => "page", :via => [:get, :post, :put]

  [:take_action, :cheque, :paypal, :paypal_completed, :paypal_cancel, :make_action].each do |action|
    match "/:page_sequence_id/#{action}" => "pages##{action}", :via => [:get, :post, :put]
    match "/:page_sequence_id/:id/#{action}" => "pages##{action}", :as => "#{action}_cloaked_page", :via => [:get, :post, :put]
    match "(/campaigns/:campaign_id)/:page_sequence_id/#{action}" => "pages##{action}", :via => [:get, :post, :put]
    match "(/campaigns/:campaign_id)/:page_sequence_id/:id/#{action}" => "pages##{action}", :as => "#{action}_page", :via => [:get, :post, :put]
  end

  constraints(CloakedDomainConstraint) do
    root :to => proc { |env|
      domain = CloakedDomain.find(env['SERVER_NAME'])
      if domain.sequence
        merged_env = env.merge({
          'action_dispatch.request.path_parameters' => {:page_sequence_id=>domain.sequence,
            :controller=>'pages', :action=>'show'}
        })
        PagesController.action(:show).call(merged_env)
      elsif domain.url
        redirect(domain.url).call(env)
      end
    }, as: :cloaked_root
  end

  root :to => "home#index"
end
