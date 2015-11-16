class NationBuilder::SyncTagsFromTjToNbService

  def sync!(tags)
    return unless NationBuilderSyncable.sync_tags?(tags)
    user_ids = User.tagged_with(tags)
    tag_users_already_in_nb(tags, user_ids)
    sync_users_who_arent_in_nb(user_ids)
  end
  handle_asynchronously :sync!, queue: "nationbuilder_api", priority: 5

  private
  
  def sync_users_who_arent_in_nb(user_ids)
    User.not_in_nationbuilder(user_ids).readonly(false).find_each(batch_size: 2000) do |user|
      # Updated the updated_at to force the user to sync over - even if 
      # there is an existing user in NB with a more recent updated_at
      user.update_column(:updated_at, Time.now)
      NationBuilder::SyncUserFromTjToNbService.new.sync! user
    end
  end

  def tag_users_already_in_nb(tags, user_ids)
    users_in_nationbuilder = User.in_nationbuilder(user_ids)
    return unless users_in_nationbuilder.exists?
    list = NationBuilder::TemporaryList.create(tags)
    list.add_people(user_ids)
    delay_in_minutes = user_ids.length > 150 ? 20 : 1
    list.delay(run_at: delay_in_minutes.minutes.from_now, queue: 'nationbuilder_api').apply_tags!
    list.delay(run_at: (120 + delay_in_minutes).minutes.from_now, queue: 'nationbuilder_api').destroy!
  end
end
