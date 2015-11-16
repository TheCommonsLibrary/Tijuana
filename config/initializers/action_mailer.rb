require_relative './app_constants'

Rails.application.routes.default_url_options[:host] = AppConstants.host
