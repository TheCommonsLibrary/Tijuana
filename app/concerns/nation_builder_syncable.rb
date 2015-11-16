module NationBuilderSyncable
  extend ActiveSupport::Concern

  included do
    scope :not_in_nationbuilder, ->(user_ids) {
      where(:id => user_ids)
        .joins('LEFT JOIN nation_builder_users ON users.id = nation_builder_users.user_id')
        .where('nation_builder_users.user_id IS NULL')
    }
    scope :in_nationbuilder, ->(user_ids) {
      where(:id => user_ids)
        .joins('INNER JOIN nation_builder_users ON users.id = nation_builder_users.user_id')
    }

    after_create :sync_created_user_to_nationbuilder
    around_update :sync_changes_to_updated_user_to_nationbuilder
  end

  def sync_created_user_to_nationbuilder
    if AppConstants.nationbuilder_sync_user_after_save
      NationBuilder::SyncUserFromTjToNbService.new.sync! self
    end
  end

  def sync_changes_to_updated_user_to_nationbuilder
    changed_attributes = changed - ["updated_at"]
    yield
    if AppConstants.nationbuilder_sync_user_after_save
      NationBuilder::SyncUserFromTjToNbService.new.sync! self, only_sync_these_attributes: changed_attributes
    end
  end
  
  def sync_tags
    NationBuilderSyncable.sync_tags(tag_list)
  end
  
  def sync_tags?
    NationBuilderSyncable.sync_tags?(tag_list)
  end
  
  def self.sync_tags(tags)
    tags.grep /sync.?$/i
  end
  
  def self.sync_tags?(tags)
    sync_tags(tags).present?
  end
end
