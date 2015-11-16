module Admin::AcquisitionSourcesHelper
  def public_link_with_source_tracking(source)
    token = EmailTrackingToken.encode_with_source(source.id)
    params = {utm_source: source.source, utm_medium: source.medium, utm_content: source.content, utm_name: source.slug, t: token}
    friendly_path_from_acq_source(source, params)
  end

  def friendly_path_from_acq_source(source, params={})
    page_url(source.page.page_sequence.campaign.friendly_id, source.page.page_sequence.friendly_id, source.page.friendly_id, params)
  end

  def redirects_for_share_link(source)
    Redirect.where('target rlike ?', "#{friendly_path_from_acq_source(source)}($|\\?)")
  end
end
