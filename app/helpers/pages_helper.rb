module PagesHelper
  def content_module_partial(content_module)
    "pages/content_modules/#{content_module.class.name.underscore}"
  end

  def exclude_module_from_daisy_chain?(content_module)
    return unless params[:via] && @page.daisy_chain?
    Page.find(params[:via]).ask_module.try(:type) == content_module.type
  end

  def take_action_path(campaign, page_sequence, page)
    if CloakedDomain.find(request.host)
      take_action_cloaked_page_path(page_sequence.friendly_id, page.friendly_id)
    else
      take_action_page_path(campaign ? campaign.friendly_id : nil, page_sequence.friendly_id, page.friendly_id)
    end
  end

  def read_more_module(rendered_content)
    {standfirst_part: rendered_content}
  end

  def generate_short_link(page, token)
    disabled_id = 0

    trackingTokenLookup = TrackingTokenLookup.new(token)
    user_id = trackingTokenLookup.valid? ? trackingTokenLookup.user.id : disabled_id
    email_id = trackingTokenLookup.valid? ? trackingTokenLookup.email.id : disabled_id

    page_url = friendly_url(page)
    page_sequence_url = friendly_url_from_page_sequence(page.page_sequence)
    redirect = Redirect.where('target = ? or target = ?', page_sequence_url, page_url).first

    redirect_id = redirect ? redirect.id : disabled_id

    hashids = Hashids.new(AppConstants.link_shortener_salt)
    hash = hashids.encode(user_id,email_id,page.id,redirect_id)

    "http://#{AppConstants.link_shortener_domain}/#{hash}"
  end

  def mp_steps_class(content_module)
    'mp-steps' if content_module.show_steps?
  end

  def no_targets_alert_class(target_options, target, postcode = nil)
    'alert alert-error' if (target_options.nil? || target_options.empty?) && target.nil? && postcode
  end

  def user_from_cookie
    User.find_by_id(cookies.signed[:user_id])
  end
end
