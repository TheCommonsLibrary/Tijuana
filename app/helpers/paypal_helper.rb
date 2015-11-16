module PaypalHelper
  include VanityHelper

  def paypal_form(page, token, form_id='occult-paypal-form', include_button=false)
    tracking_token = TrackingTokenLookup.new(token)
    parsed_token = tracking_token.valid? || tracking_token.valid_source_token? ? token : ''
    campaign = page.static? ? nil : page.page_sequence.campaign
    donation_module = page.content_modules.to_a.find { |cm| cm.is_a?(DonationModule) }
    notify_url = generate_paypal_ipn_url page.id, donation_module.id, parsed_token
    form=<<-EOF
      <form target="_top" id='#{form_id}' action="#{AppConstants.paypal_post_url}" method="post">
        <input type="hidden" name="cmd" value="_donations">
        <input type="hidden" name="lc" value="AU">
        <input type="hidden" name="item_name" value="#{item_name(campaign)}">
        <input type="hidden" name="item_number" value="#{campaign.nil? ? nil : campaign.id}">
        <input type="hidden" name="no_note" value="1">
        <input type="hidden" name="business" value="#{AppConstants.paypal_business_id}">
        <input type="hidden" name="no_shipping" value="1">
        <input type="hidden" name="rm" value="1">
        <input type="hidden" name="return" value="#{paypal_return_url(@campaign, @page_sequence, page)}">
        <input type="hidden" name="cancel_return" value="#{paypal_cancel_url(@campaign, @page_sequence, page)}">
        <input type="hidden" name="currency_code" value="AUD">
        <input type="hidden" name="bn" value="PP-DonationsBF:btn_donate_SM.gif:NonHosted">
        <input type="hidden" name="notify_url" value="#{notify_url}">
    EOF

    form += paypal_button if include_button
    form += "</form>"
    raw(form)
  end

  def paypal_cancel_url(campaign, page_sequence, page)
    if CloakedDomain.find(request.host)
      paypal_cancel_cloaked_page_url(@page_sequence, page)
    else
      paypal_cancel_page_url(@campaign, @page_sequence, page)
    end
  end


  def paypal_return_url(campaign, page_sequence, page)
    if CloakedDomain.find(request.host)
      paypal_completed_cloaked_page_url(@page_sequence, page)
    else
      paypal_completed_page_url(@campaign, @page_sequence, page)
    end
  end

  def item_name(campaign)
    name = campaign.try(:name)
    return name if name.present? && name != 'generous'
    'Campaign General'
  end

  def paypal_ipn_url(page, token)
    parsedToken = TrackingTokenLookup.new(token).valid? ? token : ''
    donation_module = page.content_modules.to_a.find { |cm| cm.is_a?(DonationModule) }
    generate_paypal_ipn_url page.id, donation_module.id, parsedToken
  end

  def paypal_button
    raw %Q{ <input id="paypal-button" type="image" src="https://www.paypal.com/en_AU/i/btn/btn_donate_SM.gif" border="0" name="submit">\n }
  end

  private

  def generate_paypal_ipn_url(page_id, module_id, token)
    "#{AppConstants.paypal_ipn_url%{page_id: page_id, module_id: module_id, token: token, vanity_identity: h(identity_from_cookie), vanity_experiments: experiment_numeric_ids_in_session}}"
  end
end
