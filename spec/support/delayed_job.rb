RSpec.configure do |config|
  config.around :each, :delay_jobs => false do |ex|
    Delayed::Worker.delay_jobs = false
    ex.run
    Delayed::Worker.delay_jobs = true
  end
end