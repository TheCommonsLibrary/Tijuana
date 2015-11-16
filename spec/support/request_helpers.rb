module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body)
    end
  end
end

RSpec.configuration.include Requests::JsonHelpers, :type => :controller
