module Stats
  class TransparencyMetric < ActiveRecord::Base
    def self.make(name, day, week, month, year)
      TransparencyMetric.new(name:name, day:day, week:week, month:month, year:year)
    end

  end
end