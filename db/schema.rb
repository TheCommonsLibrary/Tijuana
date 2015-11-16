# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180521014549) do

  create_table "acquisition_sources", force: :cascade do |t|
    t.string   "source",     limit: 255
    t.string   "medium",     limit: 255
    t.string   "content",    limit: 255
    t.string   "name",       limit: 255
    t.integer  "user_id",    limit: 4
    t.string   "slug",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_id",    limit: 4
    t.boolean  "generated",              default: false
  end

  add_index "acquisition_sources", ["slug"], name: "index_acquisition_sources_on_slug", using: :btree

  create_table "agra_actions", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "slug",       limit: 255
    t.string   "role",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "source",     limit: 255
  end

  add_index "agra_actions", ["user_id"], name: "index_agra_actions_on_user_id", using: :btree

  create_table "blasts", force: :cascade do |t|
    t.integer  "push_id",        limit: 4
    t.string   "name",           limit: 255
    t.datetime "deleted_at"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "delayed_job_id", limit: 4
    t.datetime "sent_at"
  end

  create_table "blocked_ips", force: :cascade do |t|
    t.string "ip_address", limit: 255
  end

  create_table "bookmarked_content_modules", force: :cascade do |t|
    t.integer  "content_module_id", limit: 4,  null: false
    t.string   "name",              limit: 64, null: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "call_outcomes", force: :cascade do |t|
    t.datetime "received_at"
    t.datetime "call_date"
    t.integer  "user_id",         limit: 4
    t.string   "email",           limit: 255
    t.string   "unique_call_id",  limit: 255
    t.string   "disposition",     limit: 255
    t.string   "campaign_type",   limit: 255
    t.string   "campaign_code",   limit: 255
    t.string   "campaign_name",   limit: 255
    t.string   "allocation_name", limit: 255
    t.string   "dialed_number",   limit: 255
    t.integer  "dial_attempts",   limit: 4
    t.integer  "call_duration",   limit: 4
    t.text     "payload",         limit: 65535
  end

  add_index "call_outcomes", ["email"], name: "index_call_outcomes_on_email", using: :btree
  add_index "call_outcomes", ["user_id"], name: "index_call_outcomes_on_user_id", using: :btree

  create_table "campaign_white_lists", force: :cascade do |t|
    t.integer "dark_filter_id",      limit: 4
    t.integer "user_id",             limit: 4
    t.integer "campaign_id",         limit: 4
    t.integer "joining_campaign_id", limit: 4
  end

  add_index "campaign_white_lists", ["campaign_id"], name: "index_campaign_white_lists_on_campaign_id", using: :btree
  add_index "campaign_white_lists", ["joining_campaign_id"], name: "index_campaign_white_lists_on_joining_campaign_id", using: :btree
  add_index "campaign_white_lists", ["user_id"], name: "index_campaign_white_lists_on_user_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "name",            limit: 64
    t.text     "description",     limit: 65535
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.datetime "deleted_at"
    t.string   "created_by",      limit: 255
    t.string   "updated_by",      limit: 255
    t.integer  "alternate_key",   limit: 4
    t.boolean  "opt_out",                       default: true
    t.integer  "theme_id",        limit: 4,     default: 1,     null: false
    t.string   "slug",            limit: 255
    t.string   "accounts_key",    limit: 255
    t.boolean  "quarantined"
    t.boolean  "hidden_in_admin",               default: false
  end

  add_index "campaigns", ["accounts_key"], name: "index_campaigns_on_accounts_key", using: :btree
  add_index "campaigns", ["slug"], name: "index_campaigns_on_slug", using: :btree

  create_table "candidates", force: :cascade do |t|
    t.integer  "electorate_id", limit: 4
    t.string   "seat",          limit: 255
    t.string   "state",         limit: 255
    t.string   "first_name",    limit: 255
    t.string   "last_name",     limit: 255
    t.string   "party_name",    limit: 255
    t.integer  "ballot_order",  limit: 4
    t.integer  "alp",           limit: 4
    t.integer  "grn",           limit: 4
    t.integer  "nxt",           limit: 4
    t.integer  "roi",           limit: 4
    t.integer  "awi",           limit: 4
    t.integer  "smi",           limit: 4
    t.integer  "ref",           limit: 4
    t.text     "data",          limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "candidates", ["seat"], name: "index_candidates_on_seat", using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "commentable_id",   limit: 4,     default: 0
    t.string   "commentable_type", limit: 255,   default: ""
    t.string   "title",            limit: 255,   default: ""
    t.text     "body",             limit: 65535
    t.string   "subject",          limit: 255,   default: ""
    t.integer  "user_id",          limit: 4,     default: 0,  null: false
    t.integer  "parent_id",        limit: 4
    t.integer  "lft",              limit: 4
    t.integer  "rgt",              limit: 4
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "content_module_links", force: :cascade do |t|
    t.integer "page_id",           limit: 4,  null: false
    t.integer "content_module_id", limit: 4,  null: false
    t.integer "position",          limit: 4
    t.string  "layout_container",  limit: 64
  end

  create_table "content_modules", force: :cascade do |t|
    t.string   "type",                            limit: 64,    null: false
    t.text     "content",                         limit: 65535
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.text     "options",                         limit: 65535
    t.string   "title",                           limit: 128
    t.string   "public_activity_stream_template", limit: 255
    t.integer  "alternate_key",                   limit: 4
    t.integer  "mautic_id",                       limit: 4
  end

  create_table "dark_filter_experiments", force: :cascade do |t|
    t.integer  "user_id",        limit: 4
    t.integer  "dark_filter_id", limit: 4
    t.boolean  "control"
    t.datetime "deleted_at"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "dark_filter_experiments", ["user_id"], name: "index_dark_filter_experiments_on_user_id", using: :btree

  create_table "dark_filters", force: :cascade do |t|
    t.string   "name",             limit: 100
    t.string   "type",             limit: 100
    t.boolean  "recruiting"
    t.boolean  "active_filter"
    t.integer  "experiment_limit", limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.text     "options",          limit: 65535
  end

  add_index "dark_filters", ["active_filter"], name: "index_dark_filters_on_active_filter", using: :btree
  add_index "dark_filters", ["recruiting"], name: "index_dark_filters_on_recruiting", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,        default: 0
    t.integer  "attempts",   limit: 4,        default: 0
    t.text     "handler",    limit: 16777215
    t.text     "last_error", limit: 16777215
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.string   "queue",      limit: 255
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "donation_upgrades", force: :cascade do |t|
    t.string   "donation_id",              limit: 255
    t.integer  "original_amount_in_cents", limit: 4
    t.integer  "upgrade_amount_in_cents",  limit: 4
    t.integer  "content_module_id",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "donations", force: :cascade do |t|
    t.integer  "user_id",               limit: 4,                    null: false
    t.integer  "content_module_id",     limit: 4,                    null: false
    t.integer  "amount_in_cents",       limit: 4,                    null: false
    t.string   "payment_method",        limit: 32,                   null: false
    t.string   "frequency",             limit: 32,                   null: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "card_type",             limit: 32
    t.integer  "card_expiry_month",     limit: 4
    t.integer  "card_expiry_year",      limit: 4
    t.string   "card_last_four_digits", limit: 4
    t.string   "name_on_card",          limit: 255
    t.boolean  "active",                              default: true
    t.datetime "last_donated_at"
    t.integer  "page_id",               limit: 4,                    null: false
    t.integer  "email_id",              limit: 4
    t.string   "cheque_number",         limit: 128
    t.string   "cheque_name",           limit: 255
    t.string   "cheque_bank",           limit: 255
    t.string   "cheque_branch",         limit: 255
    t.string   "trigger_id",            limit: 255
    t.datetime "last_tried_at"
    t.string   "identifier",            limit: 255
    t.string   "receipt_frequency",     limit: 255
    t.datetime "flagged_since"
    t.string   "flagged_because",       limit: 255
    t.datetime "dismissed_at"
    t.string   "assigned_to",           limit: 255
    t.datetime "assigned_date"
    t.string   "paypal_subscr_id",      limit: 255
    t.text     "dynamic_attributes",    limit: 65535
    t.string   "process_status",        limit: 255
    t.boolean  "quick_donation"
    t.string   "cheque_bsb",            limit: 255
    t.string   "cheque_account_number", limit: 255
    t.string   "cancel_reason",         limit: 255
    t.datetime "cancelled_at"
    t.datetime "make_recurring_at"
  end

  add_index "donations", ["content_module_id"], name: "donations_content_module_idx", using: :btree
  add_index "donations", ["dismissed_at"], name: "dismissed_at_idx", using: :btree
  add_index "donations", ["frequency"], name: "index_donations_on_frequency", using: :btree
  add_index "donations", ["paypal_subscr_id"], name: "index_donations_on_paypal_subscr_id", unique: true, using: :btree
  add_index "donations", ["user_id"], name: "index_donations_on_user_id", using: :btree

  create_table "downloadable_assets", force: :cascade do |t|
    t.string   "asset_file_name",    limit: 255
    t.string   "asset_content_type", limit: 128
    t.integer  "asset_file_size",    limit: 4
    t.string   "link_text",          limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "created_by",         limit: 255
    t.string   "updated_by",         limit: 255
  end

  create_table "electorates", force: :cascade do |t|
    t.string  "name",            limit: 255
    t.integer "jurisdiction_id", limit: 4
  end

  add_index "electorates", ["jurisdiction_id"], name: "electorates_jurisdiction_id_fk", using: :btree

  create_table "electorates_postcodes", id: false, force: :cascade do |t|
    t.integer "electorate_id",             limit: 4,                         default: 0, null: false
    t.integer "postcode_id",               limit: 4,                         default: 0, null: false
    t.integer "population",                limit: 4
    t.integer "total_postcode_population", limit: 4
    t.decimal "proportion",                          precision: 3, scale: 2
  end

  add_index "electorates_postcodes", ["electorate_id", "postcode_id"], name: "index_electorates_postcodes_on_electorate_id_and_postcode_id", unique: true, using: :btree
  add_index "electorates_postcodes", ["postcode_id"], name: "electorates_postcodes_postcode_id_fk", using: :btree

  create_table "electorates_pre_polling_booths", id: false, force: :cascade do |t|
    t.integer "electorate_id",        limit: 4, null: false
    t.integer "pre_polling_booth_id", limit: 4, null: false
  end

  create_table "email_pledges", force: :cascade do |t|
    t.integer  "content_module_id", limit: 4
    t.integer  "user_id",           limit: 4
    t.integer  "user_email_id",     limit: 4
    t.string   "target_email",      limit: 255
    t.string   "target_name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_target_tracking_logs", force: :cascade do |t|
    t.integer  "user_email_id", limit: 4
    t.text     "agent",         limit: 65535
    t.text     "referrer",      limit: 65535
    t.string   "ip",            limit: 255
    t.string   "cookie",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_target_tracking_logs", ["user_email_id"], name: "index_email_target_tracking_logs_on_user_email_id", using: :btree

  create_table "emails", force: :cascade do |t|
    t.integer  "blast_id",              limit: 4
    t.string   "name",                  limit: 255
    t.text     "sent_to_users_ids",     limit: 16777215
    t.string   "from_address",          limit: 255
    t.string   "reply_to_address",      limit: 255
    t.string   "subject",               limit: 255
    t.text     "body",                  limit: 16777215
    t.datetime "deleted_at"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.datetime "test_sent_at"
    t.integer  "delayed_job_id",        limit: 4
    t.string   "from_name",             limit: 255
    t.string   "footer",                limit: 255
    t.datetime "cut_completed_at"
    t.integer  "get_together_id",       limit: 4
    t.boolean  "secure_links",                           default: false
    t.boolean  "body_is_html_document",                  default: false
  end

  create_table "event_tracking_logs", force: :cascade do |t|
    t.integer  "user_id",    limit: 4
    t.string   "name",       limit: 255
    t.string   "context",    limit: 255
    t.text     "agent",      limit: 65535
    t.text     "referrer",   limit: 65535
    t.string   "ip",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "event_tracking_logs", ["user_id"], name: "index_event_tracking_logs_on_user_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.datetime "created_at",                                                                   null: false
    t.datetime "updated_at",                                                                   null: false
    t.string   "name",                 limit: 255
    t.date     "date"
    t.integer  "time",                 limit: 4
    t.string   "address",              limit: 255
    t.integer  "host_id",              limit: 4
    t.text     "host_notes",           limit: 65535
    t.datetime "deleted_at"
    t.integer  "get_together_id",      limit: 4
    t.integer  "capacity",             limit: 4
    t.string   "phone",                limit: 255
    t.string   "confirmation_code",    limit: 255
    t.datetime "confirmed_at"
    t.datetime "canceled_at"
    t.string   "postcode",             limit: 255
    t.string   "street",               limit: 255
    t.string   "suburb",               limit: 255
    t.decimal  "address_latitude",                   precision: 15, scale: 12
    t.decimal  "address_longitude",                  precision: 15, scale: 12
    t.decimal  "suburb_latitude",                    precision: 15, scale: 12
    t.decimal  "suburb_longitude",                   precision: 15, scale: 12
    t.boolean  "terms_and_conditions",                                         default: false
    t.boolean  "is_public"
    t.string   "slug",                 limit: 255
  end

  add_index "events", ["slug"], name: "index_events_on_slug", using: :btree

  create_table "events_attendees", id: false, force: :cascade do |t|
    t.integer "event_id",    limit: 4, null: false
    t.integer "attendee_id", limit: 4, null: false
  end

  add_index "events_attendees", ["event_id", "attendee_id"], name: "index_events_attendees_on_event_id_and_attendee_id", unique: true, using: :btree

  create_table "facebook_share_widget_shares", force: :cascade do |t|
    t.string   "user_facebook_id",   limit: 255
    t.string   "friend_facebook_id", limit: 255
    t.string   "url",                limit: 255
    t.text     "message",            limit: 65535
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "facebook_share_widget_shares", ["user_facebook_id", "friend_facebook_id", "url"], name: "unique_share", unique: true, using: :btree

  create_table "facebook_users", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "facebook_id", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "app_id",      limit: 8
  end

  add_index "facebook_users", ["facebook_id", "user_id", "app_id"], name: "index_facebook_users_on_facebook_id_and_user_id_and_app_id", using: :btree
  add_index "facebook_users", ["user_id", "facebook_id"], name: "index_facebook_users_on_user_id_and_facebook_id", using: :btree
  add_index "facebook_users", ["user_id"], name: "index_facebook_users_on_user_id", using: :btree

  create_table "failed_donations", force: :cascade do |t|
    t.text     "credit_card", limit: 65535
    t.integer  "donation_id", limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",           limit: 255, null: false
    t.integer  "sluggable_id",   limit: 4,   null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope",          limit: 255
    t.datetime "created_at",                 null: false
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "get_togethers", force: :cascade do |t|
    t.string   "name",                          limit: 255
    t.integer  "campaign_id",                   limit: 4
    t.date     "from_date"
    t.date     "to_date"
    t.date     "recommended_date"
    t.integer  "from_time",                     limit: 4
    t.integer  "to_time",                       limit: 4
    t.integer  "recommended_time",              limit: 4
    t.datetime "deleted_at"
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.text     "description",                   limit: 65535
    t.text     "host_greeting_email",           limit: 65535
    t.text     "attendee_greeting_email",       limit: 65535
    t.text     "options",                       limit: 65535
    t.boolean  "is_closed"
    t.integer  "theme_id",                      limit: 4
    t.integer  "content_module_id",             limit: 4
    t.boolean  "is_admin_managed",                            default: false
    t.text     "required_user_details",         limit: 65535
    t.integer  "search_radius",                 limit: 4,     default: 50,    null: false
    t.integer  "managed_get_together_id",       limit: 4
    t.string   "redirect_url",                  limit: 255
    t.text     "header_html",                   limit: 65535
    t.text     "map_footer_html",               limit: 65535
    t.text     "event_header_html",             limit: 65535
    t.text     "event_content_html",            limit: 65535
    t.text     "event_new_location_html",       limit: 65535
    t.text     "event_confirmation_html",       limit: 65535
    t.text     "event_host_notes_tooltip_html", limit: 65535
    t.text     "event_name_tooltip_html",       limit: 65535
    t.text     "event_thank_you_html",          limit: 65535
    t.text     "event_time_date_instructions",  limit: 65535
    t.text     "sidebar_content",               limit: 65535
    t.boolean  "capacity_enabled"
    t.string   "slug",                          limit: 255
  end

  add_index "get_togethers", ["slug"], name: "index_get_togethers_on_slug", using: :btree

  create_table "homepages", force: :cascade do |t|
    t.string   "banner_text",        limit: 255
    t.string   "campaign_image",     limit: 255
    t.string   "campaign_url",       limit: 255
    t.string   "campaign_alt_text",  limit: 255
    t.datetime "updated_at"
    t.string   "updated_by",         limit: 255
    t.string   "campaign2_image",    limit: 255
    t.string   "campaign2_url",      limit: 255
    t.string   "campaign2_alt_text", limit: 255
    t.string   "campaign3_image",    limit: 255
    t.string   "campaign3_url",      limit: 255
    t.string   "campaign3_alt_text", limit: 255
  end

  create_table "image_shares", force: :cascade do |t|
    t.integer  "user_id",           limit: 4,     null: false
    t.integer  "content_module_id", limit: 4,     null: false
    t.integer  "page_id",           limit: 4,     null: false
    t.integer  "email_id",          limit: 4
    t.string   "image_url",         limit: 255,   null: false
    t.text     "caption",           limit: 65535, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", force: :cascade do |t|
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 32
    t.integer  "image_file_size",    limit: 4
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.integer  "image_height",       limit: 4
    t.integer  "image_width",        limit: 4
    t.string   "image_description",  limit: 255
    t.boolean  "image_resize",                   default: false, null: false
    t.string   "created_by",         limit: 255
    t.string   "updated_by",         limit: 255
  end

  create_table "issues", force: :cascade do |t|
    t.integer  "electorate_id", limit: 4
    t.string   "state",         limit: 255
    t.string   "seat",          limit: 255
    t.string   "issue",         limit: 255
    t.string   "title",         limit: 255
    t.string   "blurb_heading", limit: 255
    t.string   "blurb_content", limit: 255
    t.string   "strap",         limit: 255
    t.string   "party_order",   limit: 255
    t.string   "alp_blurb",     limit: 255
    t.string   "grn_blurb",     limit: 255
    t.string   "awi_blurb",     limit: 255
    t.string   "smi_blurb",     limit: 255
    t.string   "nxt_blurb",     limit: 255
    t.string   "roi_blurb",     limit: 255
    t.text     "data",          limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "issues", ["seat"], name: "index_issues_on_seat", using: :btree

  create_table "jurisdictions", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "upper_house_present"
    t.string   "code",                limit: 10
  end

  create_table "list_intermediate_results", force: :cascade do |t|
    t.text     "data",       limit: 65535
    t.boolean  "ready",                    default: false
    t.integer  "list_id",    limit: 4
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "lists", force: :cascade do |t|
    t.text     "rules",      limit: 65535, null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "blast_id",   limit: 4
  end

  create_table "member_count_calculators", force: :cascade do |t|
    t.integer  "current",    limit: 4
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "member_values", force: :cascade do |t|
    t.integer  "user_id",                limit: 4, null: false
    t.integer  "campaign_id",            limit: 4
    t.integer  "page_id",                limit: 4
    t.integer  "user_activity_event_id", limit: 4
    t.integer  "transaction_id",         limit: 4
    t.boolean  "current"
    t.string   "value_type",             limit: 8
    t.integer  "cumulative_value",       limit: 4
    t.integer  "delta_value",            limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "member_values", ["transaction_id"], name: "index_member_values_on_transaction_id", using: :btree
  add_index "member_values", ["user_activity_event_id"], name: "index_member_values_on_user_activity_event_id", using: :btree
  add_index "member_values", ["user_id", "current"], name: "index_member_values_on_user_id_and_current", using: :btree
  add_index "member_values", ["user_id", "value_type", "current"], name: "index_member_values_on_user_id_and_value_type_and_current", using: :btree
  add_index "member_values", ["user_id"], name: "index_member_values_on_user_id", using: :btree
  add_index "member_values", ["value_type", "campaign_id"], name: "index_member_values_on_value_type_and_campaign_id", using: :btree

  create_table "merge_records", force: :cascade do |t|
    t.string   "join_id",    limit: 255
    t.string   "name",       limit: 255
    t.string   "value",      limit: 255
    t.integer  "merge_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "merge_records", ["merge_id", "name"], name: "index_merge_records_on_merge_id_and_name", using: :btree

  create_table "merges", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "join_key",        limit: 255
    t.string   "description",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "join_field_name", limit: 255
    t.string   "join_cache_key",  limit: 255
  end

  add_index "merges", ["name"], name: "index_merges_on_name", unique: true, using: :btree

  create_table "mps", force: :cascade do |t|
    t.string   "last_name",        limit: 255
    t.string   "first_name",       limit: 255
    t.string   "email",            limit: 255
    t.string   "parliament_phone", limit: 255
    t.string   "parliament_fax",   limit: 255
    t.string   "office_address",   limit: 255
    t.string   "office_suburb",    limit: 255
    t.string   "office_state",     limit: 255
    t.string   "office_postcode",  limit: 255
    t.string   "office_fax",       limit: 255
    t.string   "office_phone",     limit: 255
    t.integer  "party_id",         limit: 4
    t.integer  "electorate_id",    limit: 4
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.text     "mailing_address",  limit: 65535
    t.text     "mailing_suburb",   limit: 65535
    t.text     "mailing_state",    limit: 65535
    t.text     "mailing_postcode", limit: 65535
  end

  add_index "mps", ["electorate_id"], name: "mps_electorate_id_fk", using: :btree
  add_index "mps", ["party_id"], name: "mps_party_id_fk", using: :btree

  create_table "nation_builder_users", force: :cascade do |t|
    t.string   "nationbuilder_site", limit: 255
    t.integer  "nationbuilder_id",   limit: 4
    t.integer  "user_id",            limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "nation_builder_users", ["nationbuilder_id", "nationbuilder_site"], name: "site_and_id_idx", using: :btree
  add_index "nation_builder_users", ["nationbuilder_id"], name: "index_nation_builder_users_on_nationbuilder_id", using: :btree

  create_table "nationbuilder_sync_logs", force: :cascade do |t|
    t.string   "source",       limit: 255
    t.string   "destination",  limit: 255
    t.string   "method",       limit: 255
    t.string   "endpoint",     limit: 255
    t.text     "data",         limit: 65535
    t.text     "payload",      limit: 65535
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "user_id",      limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "nationbuilder_sync_logs", ["endpoint"], name: "index_nationbuilder_sync_logs_on_endpoint", using: :btree
  add_index "nationbuilder_sync_logs", ["source"], name: "index_nationbuilder_sync_logs_on_source", using: :btree
  add_index "nationbuilder_sync_logs", ["user_id"], name: "index_nationbuilder_sync_logs_on_user_id", using: :btree

  create_table "notes", force: :cascade do |t|
    t.text     "value",      limit: 65535
    t.string   "created_by", limit: 255
    t.string   "updated_by", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "old_passwords", force: :cascade do |t|
    t.string   "encrypted_password",       limit: 255
    t.string   "password_salt",            limit: 255
    t.string   "password_archivable_type", limit: 255, null: false
    t.integer  "password_archivable_id",   limit: 4,   null: false
    t.datetime "created_at"
  end

  add_index "old_passwords", ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable", using: :btree

  create_table "page_sequences", force: :cascade do |t|
    t.integer  "campaign_id",                       limit: 4
    t.string   "name",                              limit: 218
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "created_by",                        limit: 255
    t.string   "updated_by",                        limit: 255
    t.integer  "alternate_key",                     limit: 4
    t.text     "options",                           limit: 65535
    t.integer  "theme_id",                          limit: 4
    t.string   "last_page_url",                     limit: 255
    t.string   "slug",                              limit: 255
    t.boolean  "welcome_email_disabled"
    t.boolean  "quarantined"
    t.boolean  "pillar_pin",                                      default: false
    t.boolean  "pillar_show",                                     default: false
    t.text     "title",                             limit: 255
    t.text     "blurb",                             limit: 255
    t.boolean  "expired",                                         default: false
    t.datetime "expires_at"
    t.integer  "expired_redirect_page_sequence_id", limit: 4
  end

  add_index "page_sequences", ["slug"], name: "index_page_sequences_on_slug", using: :btree

  create_table "pages", force: :cascade do |t|
    t.integer  "page_sequence_id",       limit: 4
    t.string   "name",                   limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "position",               limit: 4
    t.text     "required_user_details",  limit: 65535
    t.boolean  "send_thankyou_email",                  default: false
    t.text     "thankyou_email_text",    limit: 65535
    t.string   "thankyou_email_subject", limit: 255
    t.integer  "views",                  limit: 4,     default: 0,     null: false
    t.string   "created_by",             limit: 255
    t.string   "updated_by",             limit: 255
    t.integer  "alternate_key",          limit: 4
    t.boolean  "paginate_main_content",                default: false
    t.boolean  "no_wrapper"
    t.string   "member_value_type",      limit: 8
    t.string   "slug",                   limit: 255
  end

  add_index "pages", ["slug"], name: "index_pages_on_slug", using: :btree

  create_table "parties", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.string   "abbreviation",    limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "jurisdiction_id", limit: 4
  end

  create_table "petition_signatures", force: :cascade do |t|
    t.integer  "user_id",            limit: 4,     null: false
    t.integer  "content_module_id",  limit: 4,     null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "page_id",            limit: 4,     null: false
    t.integer  "email_id",           limit: 4
    t.text     "dynamic_attributes", limit: 65535
  end

  add_index "petition_signatures", ["content_module_id"], name: "petition_signatures_content_module_id_idx", using: :btree
  add_index "petition_signatures", ["page_id"], name: "petition_signatures_page_id_idx", using: :btree

  create_table "polling_booths", force: :cascade do |t|
    t.integer  "electorate_id",  limit: 4
    t.string   "premises_name",  limit: 255
    t.string   "address",        limit: 255
    t.string   "suburb",         limit: 255
    t.decimal  "longitude",                  precision: 15, scale: 12
    t.decimal  "latitude",                   precision: 15, scale: 12
    t.integer  "postcode_id",    limit: 4
    t.string   "booth_location", limit: 255
    t.string   "booth_gate",     limit: 255
    t.string   "booth_entrance", limit: 255
    t.string   "wheelchair",     limit: 255
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
  end

  create_table "postcodes", force: :cascade do |t|
    t.string   "number",     limit: 255
    t.string   "state",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "longitude",  limit: 24
    t.float    "latitude",   limit: 24
  end

  create_table "postcodes_regions", id: false, force: :cascade do |t|
    t.integer "region_id",   limit: 4
    t.integer "postcode_id", limit: 4
  end

  add_index "postcodes_regions", ["postcode_id"], name: "postcodes_regions_postcode_id_fk", using: :btree
  add_index "postcodes_regions", ["region_id", "postcode_id"], name: "index_postcodes_regions_on_region_id_and_postcode_id", unique: true, using: :btree

  create_table "pre_polling_booths", force: :cascade do |t|
    t.string   "premises_name",  limit: 255
    t.string   "address",        limit: 255
    t.string   "suburb",         limit: 255
    t.integer  "postcode_id",    limit: 4
    t.string   "booth_location", limit: 255
    t.string   "booth_gate",     limit: 255
    t.string   "booth_entrance", limit: 255
    t.string   "wheelchair",     limit: 255
    t.text     "hours",          limit: 65535
    t.decimal  "longitude",                    precision: 15, scale: 12
    t.decimal  "latitude",                     precision: 15, scale: 12
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "push_logs", force: :cascade do |t|
    t.text     "message",    limit: 16777215
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "pushes", force: :cascade do |t|
    t.integer  "campaign_id", limit: 4
    t.string   "name",        limit: 255
    t.datetime "deleted_at"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.datetime "locked_at"
  end

  create_table "quarantines", force: :cascade do |t|
    t.integer  "user_id",                limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_activity_event_id", limit: 4
  end

  add_index "quarantines", ["user_id"], name: "index_quarantines_on_user_id", unique: true, using: :btree

  create_table "radio_shows", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "presenter",        limit: 255
    t.time     "from_time"
    t.time     "to_time"
    t.string   "website",          limit: 255
    t.string   "show_type",        limit: 255
    t.integer  "radio_station_id", limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "radio_stations", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "state",            limit: 255
    t.string   "phone",            limit: 255
    t.string   "sms",              limit: 255
    t.string   "fax",              limit: 255
    t.string   "air",              limit: 255
    t.decimal  "latitude",                     precision: 15, scale: 12
    t.decimal  "longitude",                    precision: 15, scale: 12
    t.float    "broadcast_radius", limit: 24
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  create_table "redirects", force: :cascade do |t|
    t.string   "alias_path",   limit: 128
    t.string   "target",       limit: 1024
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "alias_domain", limit: 255
  end

  add_index "redirects", ["alias_domain"], name: "index_redirects_on_alias_domain", using: :btree
  add_index "redirects", ["alias_path"], name: "index_redirects_on_alias_path", using: :btree

  create_table "regions", force: :cascade do |t|
    t.string  "name",            limit: 255
    t.integer "jurisdiction_id", limit: 4
  end

  add_index "regions", ["jurisdiction_id"], name: "regions_jurisdiction_id_fk", using: :btree

  create_table "remarketing_campaigns", force: :cascade do |t|
    t.text     "content",    limit: 65535,                 null: false
    t.boolean  "active",                   default: false
    t.text     "tags",       limit: 65535,                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority",   limit: 4,     default: 0
  end

  add_index "remarketing_campaigns", ["active"], name: "index_remarketing_campaigns_on_active", using: :btree

  create_table "senators", force: :cascade do |t|
    t.string   "last_name",        limit: 255
    t.string   "first_name",       limit: 255
    t.string   "email",            limit: 255
    t.string   "state",            limit: 255
    t.string   "parliament_phone", limit: 255
    t.string   "parliament_fax",   limit: 255
    t.string   "office_address",   limit: 255
    t.string   "office_suburb",    limit: 255
    t.string   "office_state",     limit: 255
    t.string   "office_postcode",  limit: 255
    t.string   "office_fax",       limit: 255
    t.string   "office_phone",     limit: 255
    t.string   "mailing_address",  limit: 255
    t.string   "mailing_suburb",   limit: 255
    t.string   "mailing_state",    limit: 255
    t.string   "mailing_postcode", limit: 255
    t.integer  "party_id",         limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "region_id",        limit: 4
  end

  create_table "sent_emails", force: :cascade do |t|
    t.integer  "email_id",        limit: 4
    t.string   "subject",         limit: 255
    t.text     "body",            limit: 16777215
    t.integer  "recipient_count", limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.text     "sql",             limit: 16777215
  end

  create_table "sent_trigger_emails", force: :cascade do |t|
    t.string   "key",               limit: 255
    t.datetime "sent_date"
    t.integer  "user_id",           limit: 4
    t.integer  "triggered_by_id",   limit: 4
    t.string   "triggered_by_type", limit: 255
  end

  add_index "sent_trigger_emails", ["user_id", "sent_date", "key"], name: "index_sent_trigger_emails_on_user_id_and_sent_date_and_key", using: :btree

  create_table "settings", force: :cascade do |t|
    t.string "key",   limit: 255
    t.text   "value", limit: 65535
  end

  create_table "shared_connections", force: :cascade do |t|
    t.integer  "originator_id",          limit: 4,   null: false
    t.integer  "action_taker_id",        limit: 4,   null: false
    t.string   "http_referrer",          limit: 255
    t.datetime "created_at"
    t.integer  "user_activity_event_id", limit: 4,   null: false
  end

  create_table "street_user_modules", force: :cascade do |t|
    t.integer "street_id",         limit: 4, null: false
    t.integer "user_id",           limit: 4, null: false
    t.integer "content_module_id", limit: 4, null: false
  end

  add_index "street_user_modules", ["street_id", "content_module_id"], name: "index_street_user_modules_on_street_id_and_content_module_id", unique: true, using: :btree

  create_table "streets", force: :cascade do |t|
    t.string "suburb_name", limit: 255, null: false
    t.string "name",        limit: 255, null: false
  end

  add_index "streets", ["suburb_name", "name"], name: "index_streets_on_suburb_name_and_name", unique: true, using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",        limit: 4
    t.integer  "taggable_id",   limit: 4
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id",     limit: 4
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context"], name: "taggind_idx", unique: true, using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "tag_id"], name: "tags_list_cutter_idx", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count", limit: 4,   default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "talking_points", force: :cascade do |t|
    t.integer "content_module_id", limit: 4
    t.string  "short_description", limit: 255
    t.text    "long_description",  limit: 65535
  end

  create_table "testimonials", force: :cascade do |t|
    t.integer  "facebook_user_id",  limit: 4
    t.text     "testimonial_text",  limit: 65535
    t.integer  "page_id",           limit: 4
    t.integer  "content_module_id", limit: 4
    t.integer  "email_id",          limit: 4
    t.integer  "user_id",           limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "themes", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "display_name", limit: 255
  end

  create_table "transactions", force: :cascade do |t|
    t.integer  "donation_id",     limit: 4,                   null: false
    t.boolean  "successful",                  default: false
    t.integer  "amount_in_cents", limit: 4
    t.string   "response_code",   limit: 255
    t.string   "message",         limit: 255
    t.string   "txn_ref",         limit: 255
    t.string   "bank_ref",        limit: 255
    t.string   "action_type",     limit: 255
    t.boolean  "refunded",                    default: false, null: false
    t.integer  "refund_of_id",    limit: 4
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.date     "settled_on"
    t.string   "currency",        limit: 3
    t.integer  "fee_in_cents",    limit: 4
    t.string   "status_reason",   limit: 255
    t.boolean  "invoiced",                    default: true
    t.string   "ip_address",      limit: 255
    t.string   "gateway_name",    limit: 255
    t.boolean  "recurring_flag",              default: false
  end

  add_index "transactions", ["created_at"], name: "created_at_idx", using: :btree
  add_index "transactions", ["donation_id"], name: "transactions_donation_idx", using: :btree
  add_index "transactions", ["txn_ref"], name: "index_transactions_on_txn_ref", using: :btree

  create_table "transparency_metrics", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "day",        limit: 4
    t.integer  "week",       limit: 4
    t.integer  "month",      limit: 4
    t.integer  "year",       limit: 4
    t.datetime "created_at"
  end

  create_table "unsubscribes", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "email_id",      limit: 4
    t.string   "reason",        limit: 255
    t.text     "specifics",     limit: 65535
    t.boolean  "community_run"
    t.datetime "created_at"
  end

  create_table "user_activity_events", force: :cascade do |t|
    t.integer  "user_id",                  limit: 4,   null: false
    t.string   "activity",                 limit: 64,  null: false
    t.integer  "campaign_id",              limit: 4
    t.integer  "page_sequence_id",         limit: 4
    t.integer  "page_id",                  limit: 4
    t.integer  "content_module_id",        limit: 4
    t.string   "content_module_type",      limit: 64
    t.integer  "user_response_id",         limit: 4
    t.string   "user_response_type",       limit: 64
    t.string   "public_stream_html",       limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "donation_amount_in_cents", limit: 4
    t.string   "donation_frequency",       limit: 255
    t.integer  "email_id",                 limit: 4
    t.integer  "push_id",                  limit: 4
    t.integer  "get_together_event_id",    limit: 4
    t.string   "source",                   limit: 10
    t.integer  "acquisition_source_id",    limit: 4
  end

  add_index "user_activity_events", ["acquisition_source_id"], name: "index_user_activity_events_on_acquisition_source_id", using: :btree
  add_index "user_activity_events", ["activity"], name: "activities_activity_idx", using: :btree
  add_index "user_activity_events", ["campaign_id"], name: "index_user_activity_events_on_campaign_id", using: :btree
  add_index "user_activity_events", ["created_at"], name: "index_user_activity_events_on_created_at", using: :btree
  add_index "user_activity_events", ["email_id"], name: "activities_email_id_idx", using: :btree
  add_index "user_activity_events", ["page_id"], name: "activities_page_id_idx", using: :btree
  add_index "user_activity_events", ["updated_at"], name: "user_activity_events_updated_at_idx", using: :btree
  add_index "user_activity_events", ["user_id"], name: "activities_user_id_idx", using: :btree

  create_table "user_activity_events_backup_email_data", force: :cascade do |t|
    t.integer  "user_id",                  limit: 4,   null: false
    t.string   "activity",                 limit: 64,  null: false
    t.integer  "campaign_id",              limit: 4
    t.integer  "page_sequence_id",         limit: 4
    t.integer  "page_id",                  limit: 4
    t.integer  "content_module_id",        limit: 4
    t.string   "content_module_type",      limit: 64
    t.integer  "user_response_id",         limit: 4
    t.string   "user_response_type",       limit: 64
    t.string   "public_stream_html",       limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "donation_amount_in_cents", limit: 4
    t.string   "donation_frequency",       limit: 255
    t.integer  "email_id",                 limit: 4
    t.integer  "push_id",                  limit: 4
    t.integer  "get_together_event_id",    limit: 4
  end

  add_index "user_activity_events_backup_email_data", ["activity"], name: "activities_activity_idx", using: :btree
  add_index "user_activity_events_backup_email_data", ["email_id"], name: "activities_email_id_idx", using: :btree
  add_index "user_activity_events_backup_email_data", ["page_id"], name: "activities_page_id_idx", using: :btree
  add_index "user_activity_events_backup_email_data", ["updated_at"], name: "user_activity_events_updated_at_idx", using: :btree
  add_index "user_activity_events_backup_email_data", ["user_id"], name: "activities_user_id_idx", using: :btree

  create_table "user_calls", force: :cascade do |t|
    t.integer  "page_id",            limit: 4
    t.integer  "content_module_id",  limit: 4
    t.integer  "user_id",            limit: 4
    t.integer  "email_id",           limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.text     "targets",            limit: 65535
    t.datetime "start_time"
    t.text     "dynamic_attributes", limit: 65535
  end

  create_table "user_emails", force: :cascade do |t|
    t.integer  "user_id",            limit: 4,                    null: false
    t.integer  "content_module_id",  limit: 4,                    null: false
    t.string   "subject",            limit: 255,                  null: false
    t.text     "body",               limit: 65535,                null: false
    t.text     "targets",            limit: 65535,                null: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "page_id",            limit: 4,                    null: false
    t.integer  "email_id",           limit: 4
    t.boolean  "cc_me"
    t.boolean  "send_to_target",                   default: true
    t.text     "dynamic_attributes", limit: 65535
  end

  add_index "user_emails", ["created_at"], name: "index_user_emails_on_created_at", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                        limit: 256,                   null: false
    t.string   "first_name",                   limit: 64
    t.string   "last_name",                    limit: 64
    t.string   "mobile_number",                limit: 32
    t.string   "home_number",                  limit: 32
    t.string   "street_address",               limit: 128
    t.string   "suburb",                       limit: 64
    t.string   "country_iso",                  limit: 2
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.boolean  "is_member",                                  default: true,  null: false
    t.string   "encrypted_password",           limit: 255
    t.string   "password_salt",                limit: 255
    t.string   "reset_password_token",         limit: 255
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                limit: 4,     default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",           limit: 255
    t.string   "last_sign_in_ip",              limit: 255
    t.datetime "deleted_at"
    t.boolean  "is_admin",                                   default: false
    t.string   "created_by",                   limit: 255
    t.string   "updated_by",                   limit: 255
    t.integer  "postcode_id",                  limit: 4
    t.string   "old_tags",                     limit: 3072,  default: "",    null: false
    t.boolean  "is_volunteer",                               default: false
    t.float    "random",                       limit: 24
    t.boolean  "is_agra_member",                             default: false
    t.datetime "reset_password_sent_at"
    t.text     "notes",                        limit: 65535
    t.string   "quick_donate_trigger_id",      limit: 255
    t.boolean  "low_volume",                                 default: false
    t.datetime "address_validated_at"
    t.string   "facebook_id",                  limit: 50
    t.string   "otp_secret_key",               limit: 255
    t.integer  "second_factor_attempts_count", limit: 4,     default: 0
    t.boolean  "do_not_call",                                default: false
  end

  add_index "users", ["created_at"], name: "created_at_idx", using: :btree
  add_index "users", ["deleted_at", "first_name"], name: "index_users_on_deleted_at_and_first_name", using: :btree
  add_index "users", ["deleted_at", "is_member"], name: "member_status", using: :btree
  add_index "users", ["deleted_at", "last_name"], name: "index_users_on_deleted_at_and_last_name", using: :btree
  add_index "users", ["deleted_at", "notes"], name: "index_users_on_deleted_at_and_notes", length: {"deleted_at"=>nil, "notes"=>200}, using: :btree
  add_index "users", ["deleted_at", "postcode_id"], name: "postcode_id_idx", using: :btree
  add_index "users", ["deleted_at", "suburb"], name: "index_users_on_deleted_at_and_suburb", using: :btree
  add_index "users", ["do_not_call"], name: "index_users_on_do_not_call", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, length: {"email"=>255}, using: :btree
  add_index "users", ["otp_secret_key"], name: "index_users_on_otp_secret_key", unique: true, using: :btree
  add_index "users", ["random"], name: "users_random_idx", using: :btree
  add_index "users", ["reset_password_token"], name: "users_reset_password_token_idx", using: :btree

  create_table "vanity_conversions", force: :cascade do |t|
    t.integer "vanity_experiment_id", limit: 4
    t.integer "alternative",          limit: 4
    t.integer "conversions",          limit: 4
  end

  add_index "vanity_conversions", ["vanity_experiment_id", "alternative"], name: "by_experiment_id_and_alternative", using: :btree

  create_table "vanity_experiments", force: :cascade do |t|
    t.string   "experiment_id", limit: 255
    t.integer  "outcome",       limit: 4
    t.datetime "created_at"
    t.datetime "completed_at"
    t.boolean  "enabled"
  end

  add_index "vanity_experiments", ["experiment_id"], name: "index_vanity_experiments_on_experiment_id", using: :btree

  create_table "vanity_metric_values", force: :cascade do |t|
    t.integer "vanity_metric_id", limit: 4
    t.integer "index",            limit: 4
    t.integer "value",            limit: 4
    t.string  "date",             limit: 255
  end

  add_index "vanity_metric_values", ["vanity_metric_id"], name: "index_vanity_metric_values_on_vanity_metric_id", using: :btree

  create_table "vanity_metrics", force: :cascade do |t|
    t.string   "metric_id",  limit: 255
    t.datetime "updated_at"
  end

  add_index "vanity_metrics", ["metric_id"], name: "index_vanity_metrics_on_metric_id", using: :btree

  create_table "vanity_participant_conversions", force: :cascade do |t|
    t.integer  "participant_id", limit: 4
    t.integer  "user_id",        limit: 4
    t.string   "metric",         limit: 255
    t.integer  "value",          limit: 4
    t.string   "experiment_id",  limit: 255
    t.string   "alternative",    limit: 255
    t.integer  "additional_id",  limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "vanity_participant_conversions", ["alternative"], name: "index_vanity_participant_conversions_on_alternative", using: :btree
  add_index "vanity_participant_conversions", ["experiment_id"], name: "index_vanity_participant_conversions_on_experiment_id", using: :btree
  add_index "vanity_participant_conversions", ["user_id"], name: "index_vanity_participant_conversions_on_user_id", using: :btree

  create_table "vanity_participants", force: :cascade do |t|
    t.string   "experiment_id", limit: 255
    t.string   "identity",      limit: 255
    t.integer  "shown",         limit: 4
    t.integer  "seen",          limit: 4
    t.integer  "converted",     limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "user_id",       limit: 4
  end

  add_index "vanity_participants", ["experiment_id", "converted"], name: "by_experiment_id_and_converted", using: :btree
  add_index "vanity_participants", ["experiment_id", "identity"], name: "by_experiment_id_and_identity", using: :btree
  add_index "vanity_participants", ["experiment_id", "seen"], name: "by_experiment_id_and_seen", using: :btree
  add_index "vanity_participants", ["experiment_id", "shown"], name: "by_experiment_id_and_shown", using: :btree
  add_index "vanity_participants", ["experiment_id"], name: "index_vanity_participants_on_experiment_id", using: :btree
  add_index "vanity_participants", ["identity"], name: "index_vanity_participants_on_identity", using: :btree
  add_index "vanity_participants", ["user_id"], name: "index_vanity_participants_on_user_id", using: :btree

  create_table "vision_survey_data_by_postcodes", force: :cascade do |t|
    t.integer "postcode_id",         limit: 4
    t.integer "climate_rallies",     limit: 4
    t.integer "election_volunteers", limit: 4
    t.integer "booths_covered",      limit: 4
    t.integer "num_of_members",      limit: 4
  end

  create_table "vision_survey_hashes", force: :cascade do |t|
    t.integer "user_id", limit: 4
    t.string  "key",     limit: 255
  end

  add_index "vision_survey_hashes", ["key"], name: "index_vision_survey_hashes_on_key", using: :btree

  create_table "vision_survey_q3_priority_issues", force: :cascade do |t|
    t.string "name", limit: 255, null: false
  end

  create_table "vision_survey_q3_priority_issues_vision_survey_results", id: false, force: :cascade do |t|
    t.integer "vision_survey_result_id",            limit: 4, null: false
    t.integer "vision_survey_q3_priority_issue_id", limit: 4, null: false
  end

  create_table "vision_survey_q6_skills", force: :cascade do |t|
    t.string "name", limit: 255, null: false
  end

  create_table "vision_survey_q6_skills_vision_survey_results", id: false, force: :cascade do |t|
    t.integer "vision_survey_result_id",   limit: 4, null: false
    t.integer "vision_survey_q6_skill_id", limit: 4, null: false
  end

  create_table "vision_survey_results", force: :cascade do |t|
    t.integer  "user_id",                   limit: 4,     null: false
    t.boolean  "new_details_supplied"
    t.string   "q4_priority_issue",         limit: 255
    t.text     "q7_volunteering_open_text", limit: 65535
    t.boolean  "q8_bequest"
    t.boolean  "q9_major_donor"
    t.string   "q10_facebook",              limit: 255
    t.string   "q11_youtube",               limit: 255
    t.string   "q12_twitter",               limit: 255
    t.string   "q13_blogging",              limit: 255
    t.string   "q14_google",                limit: 255
    t.string   "q18_transparency",          limit: 255
    t.datetime "created_at"
  end

  add_foreign_key "electorates", "jurisdictions", name: "electorates_jurisdiction_id_fk"
  add_foreign_key "electorates_postcodes", "electorates", name: "electorates_postcodes_electorate_id_fk"
  add_foreign_key "electorates_postcodes", "postcodes", name: "electorates_postcodes_postcode_id_fk"
  add_foreign_key "mps", "electorates", name: "mps_electorate_id_fk"
  add_foreign_key "mps", "parties", name: "mps_party_id_fk"
  add_foreign_key "postcodes_regions", "postcodes", name: "postcodes_regions_postcode_id_fk"
  add_foreign_key "postcodes_regions", "regions", name: "postcodes_regions_region_id_fk"
  add_foreign_key "regions", "jurisdictions", name: "regions_jurisdiction_id_fk"
end
