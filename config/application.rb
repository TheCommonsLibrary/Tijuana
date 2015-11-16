require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tijuana
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = "Sydney"

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # CUSTOM

    # for embedded modules
    config.action_dispatch.default_headers = { 'X-Frame-Options' => 'ALLOWALL' }

    config.autoload_paths << Rails.root.join('lib')

    # ensure all listcutter classes are properly loaded
    # before we attempt to reload the serialized versions on a worker
    config.before_initialize do |app|
      app.config.paths.add 'app/models/list_cutter', eager_load: true
    end
    config.to_prepare do
      Dir[ File.expand_path(Rails.root.join("app/models/list_cutter/*.rb")) ].each do |file|
        require_dependency file
      end
    end

    config.recalculate_member_value_after_action = true
    config.add_subscribed_members_to_dark_filter_experiments = false

    ActiveSupport::Deprecation.silenced = !Rails.env.development?
    #TODO: disable strong params for now. fix before rails5
    config.action_controller.permit_all_parameters = true

    # enable json logging for redshift
    config.lograge.enabled = true
    config.lograge.keep_original_rails_log = true
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.alternate_logger = ActiveSupport::Logger.new "#{Rails.root}/log/requests_#{Rails.env}.log"
    config.lograge.custom_options = lambda do |event|
      payload = event.payload.clone
      payload[:path] = payload[:path].try(:slice, 0, 300)
      payload
    end
  end
end
