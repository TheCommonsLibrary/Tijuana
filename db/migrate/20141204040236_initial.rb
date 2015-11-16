class Initial < ActiveRecord::Migration
	def self.up
	
	  create_table "agra_actions" do |t|
	    t.integer  "user_id"
	    t.string   "slug"
	    t.string   "role"
	    t.datetime "created_at", :null => false
	    t.datetime "updated_at", :null => false
	  end
	
	  add_index "agra_actions", ["user_id"], :name => "index_agra_actions_on_user_id"
	
	  create_table "blasts" do |t|
	    t.integer  "push_id"
	    t.string   "name"
	    t.datetime "deleted_at"
	    t.datetime "created_at",     :null => false
	    t.datetime "updated_at",     :null => false
	    t.integer  "delayed_job_id"
	    t.datetime "sent_at"
	  end
	
	  create_table "blocked_ips" do |t|
	    t.string "ip_address"
	  end
	
	  create_table "bookmarked_content_modules" do |t|
	    t.integer  "content_module_id",               :null => false
	    t.string   "name",              :limit => 64, :null => false
	    t.datetime "created_at",                      :null => false
	    t.datetime "updated_at",                      :null => false
	  end
	
	  create_table "campaign_blacklists", :id => false do |t|
	    t.integer  "user_id"
	    t.integer  "campaign_id"
	    t.datetime "created_at",  :null => false
	    t.datetime "updated_at",  :null => false
	  end
	
	  add_index "campaign_blacklists", ["user_id", "campaign_id"], :name => "user_campaign_idx"
	
	  create_table "campaign_white_lists" do |t|
	    t.integer "dark_filter_id"
	    t.integer "user_id"
	    t.integer "campaign_id"
	    t.integer "joining_campaign_id"
	  end
	
	  add_index "campaign_white_lists", ["campaign_id"], :name => "index_campaign_white_lists_on_campaign_id"
	  add_index "campaign_white_lists", ["joining_campaign_id"], :name => "index_campaign_white_lists_on_joining_campaign_id"
	  add_index "campaign_white_lists", ["user_id"], :name => "index_campaign_white_lists_on_user_id"
	
	  create_table "campaigns" do |t|
	    t.string   "name",          :limit => 64
	    t.text     "description"
	    t.datetime "created_at",                                    :null => false
	    t.datetime "updated_at",                                    :null => false
	    t.datetime "deleted_at"
	    t.string   "created_by"
	    t.string   "updated_by"
	    t.integer  "alternate_key"
	    t.boolean  "opt_out",                     :default => true
	    t.integer  "theme_id",                    :default => 1,    :null => false
	  end
	
	  create_table "comments" do |t|
	    t.integer  "commentable_id",   :default => 0
	    t.string   "commentable_type", :default => ""
	    t.string   "title",            :default => ""
	    t.text     "body"
	    t.string   "subject",          :default => ""
	    t.integer  "user_id",          :default => 0,  :null => false
	    t.integer  "parent_id"
	    t.integer  "lft"
	    t.integer  "rgt"
	    t.datetime "created_at",                       :null => false
	    t.datetime "updated_at",                       :null => false
	  end
	
	  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
	  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"
	
	  create_table "content_module_links" do |t|
	    t.integer "page_id",                         :null => false
	    t.integer "content_module_id",               :null => false
	    t.integer "position"
	    t.string  "layout_container",  :limit => 64
	  end
	
	  create_table "content_modules" do |t|
	    t.string   "type",                            :limit => 64,  :null => false
	    t.text     "content"
	    t.datetime "created_at",                                     :null => false
	    t.datetime "updated_at",                                     :null => false
	    t.text     "options"
	    t.string   "title",                           :limit => 128
	    t.string   "public_activity_stream_template"
	    t.integer  "alternate_key"
	  end
	
	  create_table "dark_filter_experiments" do |t|
	    t.integer  "user_id"
	    t.integer  "dark_filter_id"
	    t.boolean  "control"
	    t.datetime "deleted_at"
	    t.datetime "created_at",     :null => false
	    t.datetime "updated_at",     :null => false
	  end
	
	  add_index "dark_filter_experiments", ["user_id"], :name => "index_dark_filter_experiments_on_user_id"
	
	  create_table "dark_filters" do |t|
	    t.string   "name",             :limit => 100
	    t.string   "type",             :limit => 100
	    t.boolean  "recruiting"
	    t.boolean  "active_filter"
	    t.integer  "experiment_limit"
	    t.datetime "created_at",                      :null => false
	    t.datetime "updated_at",                      :null => false
	    t.text     "options"
	  end
	
	  add_index "dark_filters", ["active_filter"], :name => "index_dark_filters_on_active_filter"
	  add_index "dark_filters", ["recruiting"], :name => "index_dark_filters_on_recruiting"
	
	  create_table "delayed_jobs" do |t|
	    t.integer  "priority",   :default => 0
	    t.integer  "attempts",   :default => 0
	    t.text     "handler"
	    t.text     "last_error"
	    t.datetime "run_at"
	    t.datetime "locked_at"
	    t.datetime "failed_at"
	    t.string   "locked_by"
	    t.datetime "created_at",                :null => false
	    t.datetime "updated_at",                :null => false
	    t.string   "queue"
	  end
	
	  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"
	
	  create_table "donations" do |t|
	    t.integer  "user_id",                                                :null => false
	    t.integer  "content_module_id",                                      :null => false
	    t.integer  "amount_in_cents",                                        :null => false
	    t.string   "payment_method",        :limit => 32,                    :null => false
	    t.string   "frequency",             :limit => 32,                    :null => false
	    t.datetime "created_at",                                             :null => false
	    t.datetime "updated_at",                                             :null => false
	    t.string   "card_type",             :limit => 32
	    t.integer  "card_expiry_month"
	    t.integer  "card_expiry_year"
	    t.string   "card_last_four_digits", :limit => 4
	    t.string   "name_on_card"
	    t.boolean  "active",                               :default => true
	    t.datetime "last_donated_at"
	    t.integer  "page_id",                                                :null => false
	    t.integer  "email_id"
	    t.string   "cheque_number",         :limit => 128
	    t.string   "cheque_name"
	    t.string   "cheque_bank"
	    t.string   "cheque_branch"
	    t.string   "trigger_id"
	    t.datetime "last_tried_at"
	    t.string   "identifier"
	    t.string   "receipt_frequency"
	    t.datetime "flagged_since"
	    t.string   "flagged_because"
	    t.datetime "dismissed_at"
	    t.string   "assigned_to"
	    t.datetime "assigned_date"
	    t.string   "paypal_subscr_id"
	    t.text     "dynamic_attributes"
	    t.string   "process_status"
	    t.boolean  "quick_donation"
	    t.string   "cheque_bsb"
	    t.string   "cheque_account_number"
	  end
	
	  add_index "donations", ["content_module_id"], :name => "donations_content_module_idx"
	  add_index "donations", ["dismissed_at"], :name => "dismissed_at_idx"
	  add_index "donations", ["frequency"], :name => "index_donations_on_frequency"
	  add_index "donations", ["paypal_subscr_id"], :name => "index_donations_on_paypal_subscr_id", :unique => true
	  add_index "donations", ["user_id"], :name => "index_donations_on_user_id"
	
	  create_table "downloadable_assets" do |t|
	    t.string   "asset_file_name"
	    t.string   "asset_content_type", :limit => 128
	    t.integer  "asset_file_size"
	    t.string   "link_text"
	    t.datetime "created_at",                        :null => false
	    t.datetime "updated_at",                        :null => false
	    t.string   "created_by"
	    t.string   "updated_by"
	  end
	
	  create_table "electorates" do |t|
	    t.string  "name"
	    t.integer "jurisdiction_id"
	  end
	
	  add_index "electorates", ["jurisdiction_id"], :name => "electorates_jurisdiction_id_fk"
	
	  create_table "electorates_postcodes", :id => false do |t|
	    t.integer "electorate_id", :default => 0, :null => false
	    t.integer "postcode_id",   :default => 0, :null => false
	  end
	
	  add_index "electorates_postcodes", ["electorate_id", "postcode_id"], :name => "index_electorates_postcodes_on_electorate_id_and_postcode_id", :unique => true
	  add_index "electorates_postcodes", ["postcode_id"], :name => "electorates_postcodes_postcode_id_fk"
	
	  create_table "emails" do |t|
	    t.integer  "blast_id"
	    t.string   "name"
	    t.text     "sent_to_users_ids"
	    t.string   "from_address"
	    t.string   "reply_to_address"
	    t.string   "subject"
	    t.text     "body"
	    t.datetime "deleted_at"
	    t.datetime "created_at",        :null => false
	    t.datetime "updated_at",        :null => false
	    t.datetime "test_sent_at"
	    t.integer  "delayed_job_id"
	    t.string   "from_name"
	    t.string   "footer"
	    t.datetime "cut_completed_at"
	    t.integer  "get_together_id"
	  end
	
	  create_table "events" do |t|
	    t.datetime "created_at",                                                              :null => false
	    t.datetime "updated_at",                                                              :null => false
	    t.string   "name"
	    t.date     "date"
	    t.integer  "time"
	    t.string   "address"
	    t.integer  "host_id"
	    t.text     "host_notes"
	    t.datetime "deleted_at"
	    t.integer  "get_together_id"
	    t.integer  "capacity"
	    t.string   "phone"
	    t.string   "confirmation_code"
	    t.datetime "confirmed_at"
	    t.datetime "canceled_at"
	    t.string   "postcode"
	    t.string   "street"
	    t.string   "suburb"
	    t.decimal  "address_latitude",     :precision => 15, :scale => 12
	    t.decimal  "address_longitude",    :precision => 15, :scale => 12
	    t.decimal  "suburb_latitude",      :precision => 15, :scale => 12
	    t.decimal  "suburb_longitude",     :precision => 15, :scale => 12
	    t.boolean  "terms_and_conditions",                                 :default => false
	    t.boolean  "is_public"
	  end
	
	  create_table "events_attendees", :id => false do |t|
	    t.integer "event_id",    :null => false
	    t.integer "attendee_id", :null => false
	  end
	
	  add_index "events_attendees", ["event_id", "attendee_id"], :name => "index_events_attendees_on_event_id_and_attendee_id", :unique => true
	
	  create_table "facebook_share_widget_shares" do |t|
	    t.string   "user_facebook_id"
	    t.string   "friend_facebook_id"
	    t.string   "url"
	    t.text     "message"
	    t.datetime "created_at",         :null => false
	    t.datetime "updated_at",         :null => false
	  end
	
	  add_index "facebook_share_widget_shares", ["user_facebook_id", "friend_facebook_id", "url"], :name => "unique_share", :unique => true
	
	  create_table "failed_donations" do |t|
	    t.text     "credit_card"
	    t.integer  "donation_id"
	    t.datetime "created_at",  :null => false
	    t.datetime "updated_at",  :null => false
	  end
	
	  create_table "get_togethers" do |t|
	    t.string   "name"
	    t.integer  "campaign_id"
	    t.date     "from_date"
	    t.date     "to_date"
	    t.date     "recommended_date"
	    t.integer  "from_time"
	    t.integer  "to_time"
	    t.integer  "recommended_time"
	    t.datetime "deleted_at"
	    t.datetime "created_at",                                       :null => false
	    t.datetime "updated_at",                                       :null => false
	    t.text     "description"
	    t.text     "host_greeting_email"
	    t.text     "attendee_greeting_email"
	    t.text     "options"
	    t.boolean  "is_closed"
	    t.integer  "theme_id"
	    t.integer  "content_module_id"
	    t.boolean  "is_admin_managed",              :default => false
	    t.text     "required_user_details"
	    t.integer  "search_radius",                 :default => 50,    :null => false
	    t.integer  "managed_get_together_id"
	    t.string   "redirect_url"
	    t.text     "header_html"
	    t.text     "map_footer_html"
	    t.text     "event_header_html"
	    t.text     "event_content_html"
	    t.text     "event_new_location_html"
	    t.text     "event_confirmation_html"
	    t.text     "event_host_notes_tooltip_html"
	    t.text     "event_name_tooltip_html"
	    t.text     "event_thank_you_html"
	    t.text     "event_time_date_instructions"
	    t.text     "sidebar_content"
	    t.boolean  "capacity_enabled"
	  end
	
	  create_table "homepages" do |t|
	    t.string   "banner_text"
	    t.string   "campaign_image"
	    t.string   "campaign_url"
	    t.string   "campaign_alt_text"
	    t.datetime "updated_at"
	    t.string   "updated_by"
	    t.string   "campaign2_image"
	    t.string   "campaign2_url"
	    t.string   "campaign2_alt_text"
	    t.string   "campaign3_image"
	    t.string   "campaign3_url"
	    t.string   "campaign3_alt_text"
	  end
	
	  create_table "images" do |t|
	    t.string   "image_file_name"
	    t.string   "image_content_type", :limit => 32
	    t.integer  "image_file_size"
	    t.datetime "created_at",                                          :null => false
	    t.datetime "updated_at",                                          :null => false
	    t.integer  "image_height"
	    t.integer  "image_width"
	    t.string   "image_description"
	    t.boolean  "image_resize",                     :default => false, :null => false
	    t.string   "created_by"
	    t.string   "updated_by"
	  end
	
	  create_table "jurisdictions" do |t|
	    t.string   "name"
	    t.datetime "created_at",                        :null => false
	    t.datetime "updated_at",                        :null => false
	    t.boolean  "upper_house_present"
	    t.string   "code",                :limit => 10
	  end
	
	  create_table "list_intermediate_results" do |t|
	    t.text     "data"
	    t.boolean  "ready",      :default => false
	    t.integer  "list_id"
	    t.datetime "created_at",                    :null => false
	    t.datetime "updated_at",                    :null => false
	  end
	
	  create_table "lists" do |t|
	    t.text     "rules",      :null => false
	    t.datetime "created_at", :null => false
	    t.datetime "updated_at", :null => false
	    t.integer  "blast_id"
	  end
	
	  create_table "member_count_calculators" do |t|
	    t.integer  "current"
	    t.datetime "created_at", :null => false
	    t.datetime "updated_at", :null => false
	  end
	
	  create_table "member_values" do |t|
	    t.integer  "user_id",                             :null => false
	    t.integer  "campaign_id"
	    t.integer  "page_id"
	    t.integer  "user_activity_event_id"
	    t.integer  "transaction_id"
	    t.boolean  "current"
	    t.string   "value_type",             :limit => 8
	    t.integer  "cumulative_value"
	    t.integer  "delta_value"
	    t.datetime "created_at",                          :null => false
	    t.datetime "updated_at",                          :null => false
	  end
	
	  add_index "member_values", ["transaction_id"], :name => "index_member_values_on_transaction_id"
	  add_index "member_values", ["user_activity_event_id"], :name => "index_member_values_on_user_activity_event_id"
	  add_index "member_values", ["user_id", "current"], :name => "index_member_values_on_user_id_and_current"
	  add_index "member_values", ["user_id", "value_type", "current"], :name => "index_member_values_on_user_id_and_value_type_and_current"
	  add_index "member_values", ["user_id"], :name => "index_member_values_on_user_id"
	  add_index "member_values", ["value_type", "campaign_id"], :name => "index_member_values_on_value_type_and_campaign_id"
	
	  create_table "mps" do |t|
	    t.string   "last_name"
	    t.string   "first_name"
	    t.string   "email"
	    t.string   "parliament_phone"
	    t.string   "parliament_fax"
	    t.string   "office_address"
	    t.string   "office_suburb"
	    t.string   "office_state"
	    t.string   "office_postcode"
	    t.string   "office_fax"
	    t.string   "office_phone"
	    t.integer  "party_id"
	    t.integer  "electorate_id"
	    t.datetime "created_at",       :null => false
	    t.datetime "updated_at",       :null => false
	  end
	
	  add_index "mps", ["electorate_id"], :name => "mps_electorate_id_fk"
	  add_index "mps", ["party_id"], :name => "mps_party_id_fk"
	
	  create_table "notes" do |t|
	    t.text     "value"
	    t.string   "created_by"
	    t.string   "updated_by"
	    t.datetime "created_at", :null => false
	    t.datetime "updated_at", :null => false
	  end
	
	  create_table "old_passwords" do |t|
	    t.string   "encrypted_password"
	    t.string   "password_salt"
	    t.string   "password_archivable_type", :null => false
	    t.integer  "password_archivable_id",   :null => false
	    t.datetime "created_at"
	  end
	
	  add_index "old_passwords", ["password_archivable_type", "password_archivable_id"], :name => "index_password_archivable"
	
	  create_table "page_sequences" do |t|
	    t.integer  "campaign_id"
	    t.string   "name",          :limit => 64
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.datetime "deleted_at"
	    t.string   "created_by"
	    t.string   "updated_by"
	    t.integer  "alternate_key"
	    t.text     "options"
	    t.integer  "theme_id"
	    t.string   "last_page_url"
	  end
	
	  create_table "pages" do |t|
	    t.integer  "page_sequence_id"
	    t.string   "name",                   :limit => 64
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.datetime "deleted_at"
	    t.integer  "position"
	    t.text     "required_user_details"
	    t.boolean  "send_thankyou_email",                  :default => false
	    t.text     "thankyou_email_text"
	    t.string   "thankyou_email_subject"
	    t.integer  "views",                                :default => 0,     :null => false
	    t.string   "created_by"
	    t.string   "updated_by"
	    t.integer  "alternate_key"
	    t.boolean  "paginate_main_content",                :default => false
	    t.boolean  "no_wrapper"
	    t.string   "member_value_type",      :limit => 8
	  end
	
	  create_table "parties" do |t|
	    t.string   "name"
	    t.string   "abbreviation"
	    t.datetime "created_at",      :null => false
	    t.datetime "updated_at",      :null => false
	    t.integer  "jurisdiction_id"
	  end
	
	  create_table "petition_signatures" do |t|
	    t.integer  "user_id",            :null => false
	    t.integer  "content_module_id",  :null => false
	    t.datetime "created_at",         :null => false
	    t.datetime "updated_at",         :null => false
	    t.integer  "page_id",            :null => false
	    t.integer  "email_id"
	    t.text     "dynamic_attributes"
	  end
	
	  add_index "petition_signatures", ["content_module_id"], :name => "petition_signatures_content_module_id_idx"
	  add_index "petition_signatures", ["page_id"], :name => "petition_signatures_page_id_idx"
	
	  create_table "polling_booths" do |t|
	    t.integer  "electorate_id"
	    t.string   "premises_name"
	    t.string   "address"
	    t.string   "suburb"
	    t.decimal  "longitude",      :precision => 15, :scale => 12
	    t.decimal  "latitude",       :precision => 15, :scale => 12
	    t.integer  "postcode_id"
	    t.string   "booth_location"
	    t.string   "booth_gate"
	    t.string   "booth_entrance"
	    t.string   "wheelchair"
	    t.datetime "created_at",                                     :null => false
	    t.datetime "updated_at",                                     :null => false
	  end
	
	  create_table "postcodes" do |t|
	    t.string   "number"
	    t.string   "state"
	    t.datetime "created_at"
	    t.datetime "updated_at"
	    t.float    "longitude"
	    t.float    "latitude"
	  end
	
	  create_table "postcodes_regions", :id => false do |t|
	    t.integer "region_id"
	    t.integer "postcode_id"
	  end
	
	  add_index "postcodes_regions", ["postcode_id"], :name => "postcodes_regions_postcode_id_fk"
	  add_index "postcodes_regions", ["region_id", "postcode_id"], :name => "index_postcodes_regions_on_region_id_and_postcode_id", :unique => true
	
	  create_table "push_logs" do |t|
	    t.text     "message",    :limit => 16777215
	    t.datetime "created_at",                     :null => false
	    t.datetime "updated_at",                     :null => false
	  end
	
	  create_table "pushes" do |t|
	    t.integer  "campaign_id"
	    t.string   "name"
	    t.datetime "deleted_at"
	    t.datetime "created_at",  :null => false
	    t.datetime "updated_at",  :null => false
	    t.datetime "locked_at"
	  end
	
	  create_table "radio_shows" do |t|
	    t.string   "name"
	    t.string   "presenter"
	    t.time     "from_time"
	    t.time     "to_time"
	    t.string   "website"
	    t.string   "show_type"
	    t.integer  "radio_station_id"
	    t.datetime "created_at",       :null => false
	    t.datetime "updated_at",       :null => false
	  end
	
	  create_table "radio_stations" do |t|
	    t.string   "name"
	    t.string   "state"
	    t.string   "phone"
	    t.string   "sms"
	    t.string   "fax"
	    t.string   "air"
	    t.decimal  "latitude",         :precision => 15, :scale => 12
	    t.decimal  "longitude",        :precision => 15, :scale => 12
	    t.float    "broadcast_radius"
	    t.datetime "created_at",                                       :null => false
	    t.datetime "updated_at",                                       :null => false
	  end
	
	  create_table "redirects" do |t|
	    t.string   "alias_path",   :limit => 128
	    t.string   "target",       :limit => 1024
	    t.datetime "created_at",                   :null => false
	    t.datetime "updated_at",                   :null => false
	    t.string   "alias_domain"
	  end
	
	  add_index "redirects", ["alias_domain"], :name => "index_redirects_on_alias_domain"
	  add_index "redirects", ["alias_path"], :name => "index_redirects_on_alias_path"
	
	  create_table "regions" do |t|
	    t.string  "name"
	    t.integer "jurisdiction_id"
	  end
	
	  add_index "regions", ["jurisdiction_id"], :name => "regions_jurisdiction_id_fk"
	
	  create_table "senators" do |t|
	    t.string   "last_name"
	    t.string   "first_name"
	    t.string   "email"
	    t.string   "state"
	    t.string   "parliament_phone"
	    t.string   "parliament_fax"
	    t.string   "office_address"
	    t.string   "office_suburb"
	    t.string   "office_state"
	    t.string   "office_postcode"
	    t.string   "office_fax"
	    t.string   "office_phone"
	    t.string   "mailing_address"
	    t.string   "mailing_suburb"
	    t.string   "mailing_state"
	    t.string   "mailing_postcode"
	    t.integer  "party_id"
	    t.datetime "created_at",       :null => false
	    t.datetime "updated_at",       :null => false
	    t.integer  "region_id"
	  end
	
	  create_table "sent_emails" do |t|
	    t.integer  "email_id"
	    t.string   "subject"
	    t.text     "body"
	    t.integer  "recipient_count"
	    t.datetime "created_at",                          :null => false
	    t.datetime "updated_at",                          :null => false
	    t.text     "sql",             :limit => 16777215
	  end
	
	  create_table "settings" do |t|
	    t.string "key"
	    t.string "value"
	  end
	
	  create_table "shared_connections" do |t|
	    t.integer  "originator_id",          :null => false
	    t.integer  "action_taker_id",        :null => false
	    t.string   "http_referrer"
	    t.datetime "created_at"
	    t.integer  "user_activity_event_id", :null => false
	  end
	
	  create_table "slugs" do |t|
	    t.string   "name"
	    t.integer  "sluggable_id"
	    t.integer  "sequence",                     :default => 1, :null => false
	    t.string   "sluggable_type", :limit => 40
	    t.string   "scope"
	    t.datetime "created_at"
	  end
	
	  add_index "slugs", ["name", "sluggable_type", "sequence", "scope"], :name => "index_slugs_on_n_s_s_and_s", :unique => true
	  add_index "slugs", ["sluggable_id"], :name => "index_slugs_on_sluggable_id"
	
	  create_table "street_user_modules" do |t|
	    t.integer "street_id",         :null => false
	    t.integer "user_id",           :null => false
	    t.integer "content_module_id", :null => false
	  end
	
	  add_index "street_user_modules", ["street_id", "content_module_id"], :name => "index_street_user_modules_on_street_id_and_content_module_id", :unique => true
	
	  create_table "streets" do |t|
	    t.string "suburb_name", :null => false
	    t.string "name",        :null => false
	  end
	
	  add_index "streets", ["suburb_name", "name"], :name => "index_streets_on_suburb_name_and_name", :unique => true
	
	  create_table "taggings" do |t|
	    t.integer  "tag_id"
	    t.integer  "taggable_id"
	    t.string   "taggable_type"
	    t.integer  "tagger_id"
	    t.string   "tagger_type"
	    t.string   "context",       :limit => 128
	    t.datetime "created_at"
	  end
	
	  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], :name => "taggings_idx", :unique => true
	
	  create_table "tags" do |t|
	    t.string  "name"
	    t.integer "taggings_count", :default => 0
	  end
	
	  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true
	
	  create_table "talking_points" do |t|
	    t.integer "content_module_id"
	    t.string  "short_description"
	    t.text    "long_description"
	  end
	
	  create_table "themes" do |t|
	    t.string   "name"
	    t.datetime "created_at",   :null => false
	    t.datetime "updated_at",   :null => false
	    t.string   "display_name"
	  end
	
	  create_table "transactions" do |t|
	    t.integer  "donation_id",                                     :null => false
	    t.boolean  "successful",                   :default => false
	    t.integer  "amount_in_cents"
	    t.string   "response_code"
	    t.string   "message"
	    t.string   "txn_ref"
	    t.integer  "bank_ref"
	    t.string   "action_type"
	    t.boolean  "refunded",                     :default => false, :null => false
	    t.integer  "refund_of_id"
	    t.datetime "created_at",                                      :null => false
	    t.datetime "updated_at",                                      :null => false
	    t.date     "settled_on"
	    t.string   "currency",        :limit => 3
	    t.integer  "fee_in_cents"
	    t.string   "status_reason"
	    t.boolean  "invoiced",                     :default => true
	    t.string   "ip_address"
	  end
	
	  add_index "transactions", ["created_at"], :name => "created_at_idx"
	  add_index "transactions", ["donation_id"], :name => "transactions_donation_idx"
	  add_index "transactions", ["txn_ref"], :name => "index_transactions_on_txn_ref"
	
	  create_table "transparency_metrics" do |t|
	    t.string   "name"
	    t.integer  "day"
	    t.integer  "week"
	    t.integer  "month"
	    t.integer  "year"
	    t.datetime "created_at"
	  end
	
	  create_table "unsubscribes" do |t|
	    t.integer  "user_id"
	    t.integer  "email_id"
	    t.string   "reason"
	    t.text     "specifics"
	    t.boolean  "community_run"
	    t.datetime "created_at"
	  end
	
	  create_table "user_activity_events" do |t|
	    t.integer  "user_id",                                :null => false
	    t.string   "activity",                 :limit => 64, :null => false
	    t.integer  "campaign_id"
	    t.integer  "page_sequence_id"
	    t.integer  "page_id"
	    t.integer  "content_module_id"
	    t.string   "content_module_type",      :limit => 64
	    t.integer  "user_response_id"
	    t.string   "user_response_type",       :limit => 64
	    t.string   "public_stream_html"
	    t.datetime "created_at",                             :null => false
	    t.datetime "updated_at",                             :null => false
	    t.integer  "donation_amount_in_cents"
	    t.string   "donation_frequency"
	    t.integer  "email_id"
	    t.integer  "push_id"
	    t.integer  "get_together_event_id"
	    t.string   "source",                   :limit => 10
	  end
	
	  add_index "user_activity_events", ["activity"], :name => "activities_activity_idx"
	  add_index "user_activity_events", ["campaign_id"], :name => "index_user_activity_events_on_campaign_id"
	  add_index "user_activity_events", ["email_id"], :name => "activities_email_id_idx"
	  add_index "user_activity_events", ["page_id"], :name => "activities_page_id_idx"
	  add_index "user_activity_events", ["updated_at"], :name => "user_activity_events_updated_at_idx"
	  add_index "user_activity_events", ["user_id"], :name => "activities_user_id_idx"
	
	  create_table "user_activity_events_backup_email_data" do |t|
	    t.integer  "user_id",                                :null => false
	    t.string   "activity",                 :limit => 64, :null => false
	    t.integer  "campaign_id"
	    t.integer  "page_sequence_id"
	    t.integer  "page_id"
	    t.integer  "content_module_id"
	    t.string   "content_module_type",      :limit => 64
	    t.integer  "user_response_id"
	    t.string   "user_response_type",       :limit => 64
	    t.string   "public_stream_html"
	    t.datetime "created_at",                             :null => false
	    t.datetime "updated_at",                             :null => false
	    t.integer  "donation_amount_in_cents"
	    t.string   "donation_frequency"
	    t.integer  "email_id"
	    t.integer  "push_id"
	    t.integer  "get_together_event_id"
	  end
	
	  add_index "user_activity_events_backup_email_data", ["activity"], :name => "activities_activity_idx"
	  add_index "user_activity_events_backup_email_data", ["email_id"], :name => "activities_email_id_idx"
	  add_index "user_activity_events_backup_email_data", ["page_id"], :name => "activities_page_id_idx"
	  add_index "user_activity_events_backup_email_data", ["updated_at"], :name => "user_activity_events_updated_at_idx"
	  add_index "user_activity_events_backup_email_data", ["user_id"], :name => "activities_user_id_idx"
	
	  create_table "user_calls" do |t|
	    t.integer  "page_id"
	    t.integer  "content_module_id"
	    t.integer  "user_id"
	    t.integer  "email_id"
	    t.datetime "created_at",        :null => false
	    t.datetime "updated_at",        :null => false
	    t.text     "targets"
	  end
	
	  create_table "user_emails" do |t|
	    t.integer  "user_id",           :null => false
	    t.integer  "content_module_id", :null => false
	    t.string   "subject",           :null => false
	    t.text     "body",              :null => false
	    t.text     "targets",           :null => false
	    t.datetime "created_at",        :null => false
	    t.datetime "updated_at",        :null => false
	    t.integer  "page_id",           :null => false
	    t.integer  "email_id"
	    t.boolean  "cc_me"
	  end
	
	  create_table "users" do |t|
	    t.string   "email",                        :limit => 256,                     :null => false
	    t.string   "first_name",                   :limit => 64
	    t.string   "last_name",                    :limit => 64
	    t.string   "mobile_number",                :limit => 32
	    t.string   "home_number",                  :limit => 32
	    t.string   "street_address",               :limit => 128
	    t.string   "suburb",                       :limit => 64
	    t.string   "country_iso",                  :limit => 2
	    t.datetime "created_at",                                                      :null => false
	    t.datetime "updated_at",                                                      :null => false
	    t.boolean  "is_member",                                    :default => true,  :null => false
	    t.string   "encrypted_password"
	    t.string   "password_salt"
	    t.string   "reset_password_token"
	    t.datetime "remember_created_at"
	    t.integer  "sign_in_count",                                :default => 0
	    t.datetime "current_sign_in_at"
	    t.datetime "last_sign_in_at"
	    t.string   "current_sign_in_ip"
	    t.string   "last_sign_in_ip"
	    t.datetime "deleted_at"
	    t.boolean  "is_admin",                                     :default => false
	    t.string   "created_by"
	    t.string   "updated_by"
	    t.integer  "postcode_id"
	    t.string   "tags",                         :limit => 3072, :default => "",    :null => false
	    t.boolean  "is_volunteer",                                 :default => false
	    t.float    "random"
	    t.boolean  "is_agra_member",                               :default => true
	    t.datetime "reset_password_sent_at"
	    t.text     "notes"
	    t.string   "quick_donate_trigger_id"
	    t.boolean  "low_volume",                                   :default => false
	    t.datetime "address_validated_at"
	    t.string   "facebook_id",                  :limit => 50
	    t.string   "otp_secret_key"
	    t.integer  "second_factor_attempts_count",                 :default => 0
	  end
	
	  add_index "users", ["created_at"], :name => "created_at_idx"
	  add_index "users", ["deleted_at", "first_name"], :name => "index_users_on_deleted_at_and_first_name"
	  add_index "users", ["deleted_at", "is_member"], :name => "member_status"
	  add_index "users", ["deleted_at", "last_name"], :name => "index_users_on_deleted_at_and_last_name"
	  add_index "users", ["deleted_at", "notes"], :name => "index_users_on_deleted_at_and_notes", :length => {"deleted_at"=>nil, "notes"=>200}
	  add_index "users", ["deleted_at", "postcode_id"], :name => "postcode_id_idx"
	  add_index "users", ["deleted_at", "suburb"], :name => "index_users_on_deleted_at_and_suburb"
	  add_index "users", ["email"], :name => "index_users_on_email", :unique => true, :length => {"email"=>255}
	  add_index "users", ["otp_secret_key"], :name => "index_users_on_otp_secret_key", :unique => true
	  add_index "users", ["random"], :name => "users_random_idx"
	  add_index "users", ["reset_password_token"], :name => "users_reset_password_token_idx"
	
	  create_table "vanity_conversions" do |t|
	    t.integer "vanity_experiment_id"
	    t.integer "alternative"
	    t.integer "conversions"
	  end
	
	  add_index "vanity_conversions", ["vanity_experiment_id", "alternative"], :name => "by_experiment_id_and_alternative"
	
	  create_table "vanity_experiments" do |t|
	    t.string   "experiment_id"
	    t.integer  "outcome"
	    t.datetime "created_at"
	    t.datetime "completed_at"
	  end
	
	  add_index "vanity_experiments", ["experiment_id"], :name => "index_vanity_experiments_on_experiment_id"
	
	  create_table "vanity_metric_values" do |t|
	    t.integer "vanity_metric_id"
	    t.integer "index"
	    t.integer "value"
	    t.string  "date"
	  end
	
	  add_index "vanity_metric_values", ["vanity_metric_id"], :name => "index_vanity_metric_values_on_vanity_metric_id"
	
	  create_table "vanity_metrics" do |t|
	    t.string   "metric_id"
	    t.datetime "updated_at"
	  end
	
	  add_index "vanity_metrics", ["metric_id"], :name => "index_vanity_metrics_on_metric_id"
	
	  create_table "vanity_participant_conversions" do |t|
	    t.integer  "participant_id"
	    t.integer  "user_id"
	    t.string   "metric"
	    t.integer  "value"
	    t.string   "experiment_id"
	    t.string   "alternative"
	    t.integer  "additional_id"
	    t.datetime "created_at",     :null => false
	    t.datetime "updated_at",     :null => false
	  end
	
	  add_index "vanity_participant_conversions", ["alternative"], :name => "index_vanity_participant_conversions_on_alternative"
	  add_index "vanity_participant_conversions", ["experiment_id"], :name => "index_vanity_participant_conversions_on_experiment_id"
	  add_index "vanity_participant_conversions", ["user_id"], :name => "index_vanity_participant_conversions_on_user_id"
	
	  create_table "vanity_participants" do |t|
	    t.string   "experiment_id"
	    t.string   "identity"
	    t.integer  "shown"
	    t.integer  "seen"
	    t.integer  "converted"
	    t.datetime "created_at",    :null => false
	    t.datetime "updated_at",    :null => false
	    t.integer  "user_id"
	  end
	
	  add_index "vanity_participants", ["experiment_id", "converted"], :name => "by_experiment_id_and_converted"
	  add_index "vanity_participants", ["experiment_id", "identity"], :name => "by_experiment_id_and_identity"
	  add_index "vanity_participants", ["experiment_id", "seen"], :name => "by_experiment_id_and_seen"
	  add_index "vanity_participants", ["experiment_id", "shown"], :name => "by_experiment_id_and_shown"
	  add_index "vanity_participants", ["experiment_id"], :name => "index_vanity_participants_on_experiment_id"
	  add_index "vanity_participants", ["user_id"], :name => "index_vanity_participants_on_user_id"
	
	  create_table "vision_survey_data_by_postcodes" do |t|
	    t.integer "postcode_id"
	    t.integer "climate_rallies"
	    t.integer "election_volunteers"
	    t.integer "booths_covered"
	    t.integer "num_of_members"
	  end
	
	  create_table "vision_survey_hashes" do |t|
	    t.integer "user_id"
	    t.string  "key"
	  end
	
	  add_index "vision_survey_hashes", ["key"], :name => "index_vision_survey_hashes_on_key"
	
	  create_table "vision_survey_q3_priority_issues" do |t|
	    t.string "name", :null => false
	  end
	
	  create_table "vision_survey_q3_priority_issues_vision_survey_results", :id => false do |t|
	    t.integer "vision_survey_result_id",            :null => false
	    t.integer "vision_survey_q3_priority_issue_id", :null => false
	  end
	
	  create_table "vision_survey_q6_skills" do |t|
	    t.string "name", :null => false
	  end
	
	  create_table "vision_survey_q6_skills_vision_survey_results", :id => false do |t|
	    t.integer "vision_survey_result_id",   :null => false
	    t.integer "vision_survey_q6_skill_id", :null => false
	  end
	
	  create_table "vision_survey_results" do |t|
	    t.integer  "user_id",                   :null => false
	    t.boolean  "new_details_supplied"
	    t.string   "q4_priority_issue"
	    t.text     "q7_volunteering_open_text"
	    t.boolean  "q8_bequest"
	    t.boolean  "q9_major_donor"
	    t.string   "q10_facebook"
	    t.string   "q11_youtube"
	    t.string   "q12_twitter"
	    t.string   "q13_blogging"
	    t.string   "q14_google"
	    t.string   "q18_transparency"
	    t.datetime "created_at"
	  end
	
	  add_foreign_key "electorates", "jurisdictions", :name => "electorates_jurisdiction_id_fk", :dependent => :delete
	
	  add_foreign_key "electorates_postcodes", "electorates", :name => "electorates_postcodes_electorate_id_fk", :dependent => :delete
	  add_foreign_key "electorates_postcodes", "postcodes", :name => "electorates_postcodes_postcode_id_fk", :dependent => :delete
	
	  add_foreign_key "mps", "electorates", :name => "mps_electorate_id_fk", :dependent => :delete
	  add_foreign_key "mps", "parties", :name => "mps_party_id_fk", :dependent => :delete
	
	  add_foreign_key "postcodes_regions", "postcodes", :name => "postcodes_regions_postcode_id_fk", :dependent => :delete
	  add_foreign_key "postcodes_regions", "regions", :name => "postcodes_regions_region_id_fk", :dependent => :delete
	
	  add_foreign_key "regions", "jurisdictions", :name => "regions_jurisdiction_id_fk", :dependent => :delete
	
	end

	def self.down
		raise ActiveRecord::IrreversibleMigration
	end
end
