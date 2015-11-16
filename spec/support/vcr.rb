VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock # or :fakeweb
  config.configure_rspec_metadata!
  config.ignore_localhost = true
end

RSpec.configure do |config|
  config.around :each, :vcr_off => true do |ex|
    WebMock.disable!
    VCR.turn_off!(:ignore_cassettes => true)
    ex.run
    VCR.turn_on!
    WebMock.enable!
  end
end
