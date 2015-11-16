class Mautic
  MAUTICABLE_MODULES = [
    'DonationModule',
    'EmailTargetsModule',
    'PetitionModule',
    'EmailMPModule',
    'CallMPModule',
  ]
  URL = "https://#{AppConstants.mautic_domain}"
  AUTH = { "Authorization" => AppConstants.mautic_auth }
  JSON_TYPE = { "Content-Type" => "application/json" }
  FORM_TYPE = { "Content-Type" => "application/x-www-form-urlencoded" }
  DELAY_OPTS = { priority: 10, queue: 'mautic' }

  def create_form_links(content_module_ids)
    content_module_ids.each do |id|
      cm = ContentModule.find(id)
      next if cm.mautic_id || !MAUTICABLE_MODULES.include?(cm.type)

      url = "#{URL}/api/forms/new"
      payload = format_module(cm)
      headers = AUTH.merge(JSON_TYPE)
      response = Excon.post(url, body: payload.to_json, headers: headers)
      Rails.logger.info({ mautic_form_response: JSON.parse(response.body) })
      cm.update_attribute(:mautic_id, JSON.parse(response.body)["form"]["id"])
    end
  end
  handle_asynchronously :create_form_links, DELAY_OPTS

  def post_submission(mautic_id, email, value, frequency, mautic_id_cookie)
    return if !mautic_id
    url = "#{URL}/form/submit"
    payload = {
      mauticform: {
        formId: mautic_id,
        email: email,
        value: value,
        frequency: frequency,
      }
    }
    headers = AUTH.merge(FORM_TYPE)
    headers.merge!("Cookie" => "mtc_id=#{mautic_id_cookie}") if mautic_id_cookie
    response = Excon.post(url, body: payload.to_query, headers: headers)
    Rails.logger.info({ mautic_submission_response: response.body })
  end
  handle_asynchronously :post_submission, DELAY_OPTS


  private

  def format_module(cm)
    ps = cm.pages.first.page_sequence
    key = ps.campaign.accounts_key
    type = cm.type.gsub(/Module/, '')
    default = [form_field("Email", "email")]
    donation = [form_field("Value"), form_field("Frequency")]
    fields = type == 'Donation' ? default + donation : default
    {
      name: "#{cm.id} / #{key} / #{ps.name} / #{type}",
      inKioskMode: true,
      fields: fields
    }
  end

  def form_field(label, leadField = nil)
    {
      alias: label.downcase.gsub(/ /, '_'),
      label: label,
      showLabel: false,
      type: "text",
      leadField: leadField,
    }
  end
end
