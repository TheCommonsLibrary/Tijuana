
ENV["USE_PROVIDER_GATEWAY"] = "true"

Delayed::Worker.delay_jobs = false

Before('@delayed-jobs') do
  Delayed::Worker.sleep_delay = 0
  Delayed::Worker.delay_jobs = true
end

After('@delayed-jobs') do
  Delayed::Worker.sleep_delay = 0
  Delayed::Worker.delay_jobs = false
end


#Because of securepay's anti-fraud support we have to mock the request to return an IP address from the US,
#since the gift card we're using in the tests is associated with that country

Before('@from-the-us') do
  ActionDispatch::Request.class_eval do
    alias_method :old_remove_id, :remote_ip

    def remote_ip
      "75.101.145.87"
    end
  end
end

After('@from-the-us') do
  ActionDispatch::Request.class_eval do
    alias_method :remote_ip, :old_remove_id
    remove_method :old_remove_id
  end
end
