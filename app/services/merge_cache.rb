class MergeCache
  def self.fetch_merge(name)
    Rails.cache.fetch("merge.#{name}") { Merge.find_by_name(name) }
  end

  def self.fetch_join_id(user, merge)
    if merge.join_cache_key.blank?
      user.instance_eval(merge.join_key)
    else
      cache_key = user.instance_eval(merge.join_cache_key)
      Rails.cache.fetch("merge.join_id.#{merge.id}.#{cache_key}.#{merge.updated_at.to_s(:number)}") { user.instance_eval(merge.join_key) }
    end
  end

  def self.fetch_merge_value(merge, join_id, key)
    Rails.cache.fetch("merge.merge_record.#{merge.id}.#{join_id}.#{key}.#{merge.updated_at.to_s(:number)}") do
      merge.merge_records
        .where(join_id: join_id, name: key)
        .first.try(:value)
    end
  end

  def self.clear(merge)
    Rails.cache.delete("merge.#{merge.name}")
  end
end
