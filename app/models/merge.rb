class Merge  < ActiveRecord::Base
  validates_presence_of :join_key
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of :join_field_name
  validate :keys_are_on_whitelist

  has_many :merge_records, :dependent => :delete_all

  class InvalidMergeHeader < RuntimeError ; end

  def keys_are_on_whitelist
    errors.add(:join_key, 'not whitelisted')  if !join_key.blank? && !MergeToken.whitelisted?(join_key)
    errors.add(:join_cache_key, 'not whitelisted') if !join_cache_key.blank? && !MergeToken.whitelisted?(join_cache_key)
  end
end
