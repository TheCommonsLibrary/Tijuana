module RemarketingHelper
  def remarketing_content
    return unless request.get? && @secure_user && (
      @homepage ||
      !page_has_an_ask_on_it? ||
      @page.tag_list.include?('enable-remarketing')
    )

    prioritised_campaigns = RemarketingCampaign.active.order(:priority).select{|remarketing_campaign|
      !has_seen_content_this_session?(remarketing_campaign) &&
      User.where(id: @secure_user.id).tagged_with(remarketing_campaign.tags, any: true).exists? &&
      !(@page && @page.tag_list.include?("disable-remarketing-#{remarketing_campaign.id}"))
    }

    filtered_by_priority_campaigns = prioritised_campaigns.select{|remarketing_campaign|
      remarketing_campaign.priority <= prioritised_campaigns.first.priority
    }

    filtered_by_priority_campaigns.map{|remarketing_campaign|
      set_that_they_have_seen_the_content(remarketing_campaign)
      record_remarketing_event(remarketing_campaign)
      remarketing_campaign.content
    }.join.html_safe
  end

  private

  def page_has_an_ask_on_it?
    @asks.present?
  end

  def has_seen_content_this_session?(remarketing_campaign)
    cookies[session_cookie_id(remarketing_campaign)]
  end

  def set_that_they_have_seen_the_content(remarketing_campaign)
    cookies[session_cookie_id(remarketing_campaign)] = 1
  end

  def session_cookie_id(remarketing_campaign)
    "rm-#{remarketing_campaign.id}-session"
  end

  def record_remarketing_event(remarketing_campaign)
    EventTrackingLog.create!({
      user_id: @secure_user.id,
      name: 'remarketing',
      context: remarketing_campaign.id,
      referrer: request.referrer,
      agent: request.user_agent,
      ip: request.remote_ip
    })
  end
end
