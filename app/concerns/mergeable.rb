module Mergeable
  extend ActiveSupport::Concern

  def merge(name, key)
    merge = MergeCache.fetch_merge(name)
    return unless merge

    raise NotWhitelisted.new("[join_key]:#{merge.join_key} is not whitelisted") unless MergeToken.whitelisted?(merge.join_key)
    join_id = nil
    raise NotWhitelisted.new("[join_cache_key]:#{merge.join_cache_key} is not whitelisted") if !merge.join_cache_key.blank? && !MergeToken.whitelisted?(merge.join_cache_key)
    join_id = MergeCache.fetch_join_id(self, merge)

    MergeCache.fetch_merge_value(merge, join_id, key)
  end
end
