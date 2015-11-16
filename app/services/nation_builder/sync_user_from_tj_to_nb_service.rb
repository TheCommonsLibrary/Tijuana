class NationBuilder::SyncUserFromTjToNbService

  def sync!(user, only_sync_these_attributes: [])
    return if @@sync_disabled || !user.sync_tags?
    nationbuilder_user = map_fields_to_nationbuilder user
    if only_sync_these_attributes.any?
      changes = map_fields_to_nationbuilder user, only_sync_these_attributes
      upsert_user_in_nb! user.id, user.updated_at, nationbuilder_user, changes if changes.any?
    else
      upsert_user_in_nb! user.id, user.updated_at, nationbuilder_user
    end
  end

  def self.disable_sync
    @@sync_disabled = true
    yield ensure @@sync_disabled = false
  end
  cattr_accessor :sync_disabled

  MAPPING_TO_NB = {
    id: :external_id,
    email: :email,
    last_name: :last_name,
    first_name: :first_name,
    mobile_number: :mobile,
    home_number: :phone,
    street_address: [ :home_address, :address1 ],
    suburb: [ :home_address, :city ],
    postcode_number: [ :home_address, :zip ],
    postcode_state: [ :home_address, :state ],
    country_iso: [ :home_address, :country_code ],
    is_member: :email_opt_in,
    tag_list: :tags
  }

  def max_attempts
    2
  end

  def reschedule_at(current_time, attempts)
    current_time + (attempts == 1 ? 10.minutes : 24.hours)
  end

  private

  def upsert_user_in_nb!(user_id, updated_at, all_user_fields, changed_fields=all_user_fields)
    begin
      existing_nb_user = NationBuilderUser.find_by_user_id(user_id)
      if existing_nb_user
        update_existing_nb_user(existing_nb_user, updated_at, all_user_fields, changed_fields)
      else
        upsert_nb_user_by_email(user_id, updated_at, all_user_fields, changed_fields)
      end
    rescue NationBuilder::ClientError => error
      notify_nationbuilder_admins_about_api_error(user_id, error)
    end
  end
  handle_asynchronously :upsert_user_in_nb!, queue: 'nationbuilder_api', priority: 5

  def update_existing_nb_user(existing_nb_user, updated_at, all_user_fields, changed_fields=all_user_fields)
    match_response = NationBuilder::Api.call_api :people, :show, {id: existing_nb_user.nationbuilder_id}
    raise "No matching NB user for ID: #{existing_nb_user.nationbuilder_id}" unless match_response['person']
    if most_recently_updated_in_tj?(updated_at, match_response['person'])
      NationBuilder::Api.call_api :people, :update, id: existing_nb_user.nationbuilder_id, person: changed_fields
    end
  end

  def upsert_nb_user_by_email(user_id, updated_at, all_user_fields, changed_fields=all_user_fields)
    nb_api = NationBuilder::Api
    email = all_user_fields[:email]
    match_response = nb_api.call_api :people, :match, email: email
    if nb_user = match_response['person']
      if most_recently_updated_in_tj_and_primary_emails_match?(email, updated_at, nb_user)
        synced_nb_user = nb_api.call_api :people, :update, id: nb_user['id'], person: changed_fields
      end
    else
      synced_nb_user = nb_api.call_api :people, :create, person: all_user_fields
    end
    if synced_nb_user
      NationBuilderUser.record_nationbuilder_id! user_id, synced_nb_user['person']['id']
    end
  end

  def most_recently_updated_in_tj_and_primary_emails_match?(email, updated_at, nb_user)
    most_recently_updated_in_tj?(updated_at, nb_user) && email == nb_user['email']
  end

  def most_recently_updated_in_tj?(updated_at, nb_user)
    updated_at >= nb_user['updated_at'].to_time
  end

  def map_fields_to_nationbuilder(user, changed_attributes=nil)
    nb_user = {}
    fields_to_sync = changed_attributes || MAPPING_TO_NB.keys
    mapping = MAPPING_TO_NB.slice(*extract_user_fields(user, fields_to_sync))
    mapping.each do |tj_key,nb_key|
      if nb_key.is_a?(Array)
        nb_user[nb_key.first] ||= {}
        nb_user[nb_key.first][nb_key.second] = user.send(tj_key)
      elsif tj_key == :tag_list
        nb_user[nb_key] = user.sync_tags
      else
        nb_user[nb_key] = user.send(tj_key)
      end
    end
    nb_user
  end

  def extract_user_fields(user, fields_to_extract)
    fields = fields_to_extract.map(&:to_sym)
    if fields.include? :postcode_id
      fields.concat [:postcode_number, :postcode_state]
    end
    if !fields.include?(:is_member) && user.subscribing?
      fields << :is_member
    end
    fields
  end

  def notify_nationbuilder_admins_about_api_error(user_id, error)
    user = User.find(user_id)
    subject = "Failed sync from Tijuana to NationBuilder for #{user.email}"
    message = "<p>Failed to sync <a href=\"https://getup.org.au/admin/users/#{user.id}/edit\">#{user.email}</a>.</p>"
    begin
      error_data = JSON.parse(error.message)
      error_message = error_data['code'] == 'validation_failed' ? error_data['validation_errors'].to_sentence : error.message
    rescue JSON::ParserError
      error_message = error.message
    end
    message += "<p>Error: #{error_message}</p>"
    TechMailer.invalid_nationbuilder_sync(subject, message).deliver
  end
end
