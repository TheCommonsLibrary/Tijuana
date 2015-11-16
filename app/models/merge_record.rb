class MergeRecord  < ActiveRecord::Base
  belongs_to :merge

  validates_presence_of :join_id
  validates_presence_of :name
  validates_presence_of :value
  validates_presence_of :merge_id
end
