class NationBuilder::SyncUserFromNbToTjService
  
  def sync!(params)
    nb_user = params[:payload] && params[:payload][:person]
    if confirm_email_exists_there_are_sync_tags?(nb_user)
      update_user_in_tj! nb_user, params
    end
  end

  private

  def confirm_email_exists_there_are_sync_tags?(nb_user)
    nb_user && nb_user[:email].present? && nb_user[:tags].present? && NationBuilderSyncable.sync_tags(nb_user[:tags]).any?
  end

  def update_user_in_tj!(nb_user, params)
    NationBuilder::SyncUserFromTjToNbService.disable_sync do
      if nb_user[:external_id]
        begin
          tj_user = User.find(nb_user[:external_id])
        rescue ActiveRecord::RecordNotFound
          Rails.env.showcase? ? return : raise
        end
        if tj_user.email != nb_user[:email]
          if existing_user = User.find_by_email(nb_user[:email])
            notify_nationbuilder_admins_about_sync_issue(nb_user, tj_user, existing_user)
            return log_webhook tj_user, params
          end
          tj_user.email = nb_user[:email]
        end
      else
        tj_user = User.find_or_initialize_by_email nb_user[:email]
      end
      return if tj_user.is_admin?
      new_record = tj_user.new_record?
      tj_user.low_volume = true if new_record
      sync_user_details_from_nb_to_tj! nb_user, tj_user
      UserActivityEvent.subcribe_user_created_by_nb!(tj_user) if new_record
      NationBuilderUser.record_nationbuilder_id! tj_user.id, nb_user['id']
      sync_user_tags_from_nb_to_tj! nb_user, tj_user
      log_webhook tj_user, params
    end
  end
  handle_asynchronously :update_user_in_tj!, queue: 'nationbuilder_api', priority: 5

  NB_KEYS_TO_IGNORE = [
    :external_id,
    :tags,
    :email,
    [:home_address, :state]
  ]

  def sync_user_details_from_nb_to_tj!(nb_user, tj_user)
    mapping = NationBuilder::SyncUserFromTjToNbService::MAPPING_TO_NB.invert
    fields_to_sync = mapping.except(*NB_KEYS_TO_IGNORE)
    fields_to_sync.each do |nb_key, tj_key|
      if nb_key.is_a?(Array) && nb_user[nb_key.first]
        value = nb_user[nb_key.first][nb_key.second]
        if tj_key != :postcode_number || Postcode.find_by_number(value)
          nb_value = value
        end
      else
        nb_value = nb_user[nb_key]
      end
      tj_user.send :"#{tj_key}=", nb_value unless nb_value.nil? || nb_value == ''
    end
    tj_user.save!
  end

  def sync_user_tags_from_nb_to_tj!(nb_user, tj_user)
    tags_to_sync = NationBuilderSyncable.sync_tags(nb_user[:tags] || [])
    tj_user.merge_tags!(tags_to_sync) if tj_user
  end
  
  def log_webhook(user, params)
    NationBuilderSyncLog.create!({
      started_at: DateTime.now, completed_at: DateTime.now,
      source: NATION_BUILDER[:site], destination: AppConstants.host,
      endpoint: 'person_changed', data: params, user_id: user.try(:id)
    })
  end

  def notify_nationbuilder_admins_about_sync_issue(nb_user, tj_user, existing_user)
    email = nb_user[:email]
    subject = "Failed sync from NationBuilder to Tijuana for #{email}"
    message = "<p>Failed to change the email from #{tj_user.email} to #{email} for user with ID #{tj_user.id} because this email belongs to another user.</p>"
    message += "<p>Fix this by editing the <a href=\"https://#{NATION_BUILDER[:site]}.nationbuilder.com/admin/signups/#{nb_user[:id]}/edit\">NationBuilder "
    message += "user with #{email}</a> and setting their External ID to #{existing_user.id}.</p>"
    TechMailer.invalid_nationbuilder_sync(subject, message).deliver
  end
end
