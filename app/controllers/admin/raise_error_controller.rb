module Admin
  class RaiseErrorController < ApplicationController
    def blowup
      raise "As expected, we have thrown an exception"
    end
  end
end


