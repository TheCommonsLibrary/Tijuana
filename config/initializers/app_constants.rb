require 'app_constants'
AppConstants.config_path = File.expand_path('../../constants.yml', __FILE__)
AppConstants.load!
