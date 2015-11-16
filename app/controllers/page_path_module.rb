module PagePathModule
  def next_page_url(page, params={})
    path_to_url(next_page_path(page, params))
  end

  def path_to_url(path)
    "#{request.protocol}#{request.host_with_port.sub(/:80$/,"")}/#{path.sub(/^\//,"")}"
  end

  def next_page_path(page, params={})
    if page.tag_list.include?('daisy')
      if Vanity.ab_test(:automated_daisy_chain) == :treatment
        return friendly_path(next_daisy_chain_page(page), params.merge(exp: 'tmnt', via: page.id))
      else
        return friendly_path(page.next, params.merge(exp: 'ctrl'))
      end
    end

    if page.next
      friendly_path(page.next, params)
    elsif page.page_sequence.last_page_url.present?
      separator = params.blank? ? "" : "?"
      page.page_sequence.last_page_url + separator + params.to_param
    else
      root_path
    end
  end

  def friendly_path(page, preserved_params={})
    if !request.nil? && CloakedDomain.find(request.host)
      cloaked_path(page.page_sequence.friendly_id, page.friendly_id, preserved_params)
    else
      campaign_id = page.page_sequence.campaign ? page.page_sequence.campaign.friendly_id : nil
      page_path(campaign_id, page.page_sequence.friendly_id, page.friendly_id, preserved_params)
    end
  end

  def next_daisy_chain_page(page)
    return unless Setting.enabled?(:auto_daisy_chains) && page.page_sequence
    page_sequence = PageSequence.daisy_chains
      .joins(:campaign)
      .where('accounts_key = ?', page.page_sequence.campaign.accounts_key)
      .first
    page_sequence && page_sequence.pages.first
  end
end
