class VanityController < Admin::AdminController
  layout false

  use_vanity

  rescue_from 'Vanity::NoExperimentError' do |exception|
    render nothing: true
  end

  include Vanity::Rails::Dashboard

  skip_authorize_resource
  skip_authorization_check
  [:authenticate_user!, :authenticate_admin!, :set_current_user, :set_nocache_headers].each do |admin_filter|
    skip_before_filter admin_filter, only: :add_participant
  end
  skip_before_filter :set_url_options

  protected

  include VanityHelper
  after_filter :update_participant_with_user_id, only: :add_participant
end
