require_relative "../ignored_exceptions"
require_relative "../../lib/exception_notifier_rescue_and_mail_tech"

Rails.application.config.middleware.use ExceptionNotification::Rack, email: {
  email_prefix: AppConstants.tech_mail_prefix,
  sender_address: AppConstants.tech_mail_from,
  exception_recipients: AppConstants.tech_mail_to,
  ignore_exceptions: IGNORED_EXCEPTIONS,
  ignore_if:  ->(env, e) {
    (e.class == ActiveMerchant::ResponseError && e.message =~ /502/) ||
    (e.message =~ /the scheme https does not accept registry part: \*\.getup.org.au/)
  }
}
