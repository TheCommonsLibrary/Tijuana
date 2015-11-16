module DarkFilter
  class Experiment < ActiveRecord::Base
    self.table_name = 'dark_filter_experiments'
    acts_as_paranoid
    belongs_to :dark_filter, class_name: 'DarkFilter::DarkFilter'
    belongs_to :user
  end
end
