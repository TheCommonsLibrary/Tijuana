module EmailHelper
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  if defined?(ActionMailer)
    unless [:test, :activerecord, :cache, :file].include?(ActionMailer::Base.delivery_method)
      ActionMailer::Base.register_observer(EmailSpec::TestObserver)
    end
    ActionMailer::Base.perform_deliveries = true
  end
  
  def save_and_open_email
    path = "#{Rails.root}/tmp/email.html"
    File.open path, 'w' do |f|
      f.write(current_email.body)
    end
    `open #{path}`
  end
end

RSpec.configuration.include EmailHelper, :type => :feature