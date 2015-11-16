module Admin
  module AdminHelper

    def link_to_nation_builder_user_view(user)
      nb_id = user.nation_builder_user.try(:nationbuilder_id)
      if nb_id
        link_to("View in NationBuilder", 
                "https://gu.nationbuilder.com/admin/signups/#{nb_id}", {id:'nb-link'})
      end
    end

    def admin_breadcrumb_links
      crumbs = []

      page = @page
      page_sequence = page ? page.page_sequence : @page_sequence

      get_together = @get_together
      
      list = @list

      blast = @blast
      blast = list.blast if list

      push = blast ? blast.push : @push
      push = list.blast.push if (list && list.blast)
      
      campaign = page_sequence.campaign if page_sequence
      campaign = push.campaign if push
      campaign ||= @campaign

      if campaign
        crumbs << ["Campaigns", admin_campaigns_path]
        if !campaign.new_record? && (page_sequence || push || get_together)
          crumbs << [campaign.name, admin_campaign_path(campaign.id)]
        end
      end
    
      if page_sequence
        if page_sequence.static?
          crumbs << ["Static Pages", admin_static_pages_path]
        end
        if page_sequence && !page_sequence.new_record? && page
          crumbs << [page_sequence.name, admin_page_sequence_path(page_sequence.id)]
        end
      end

      if blast
        crumbs << [blast.push.name, admin_push_path(blast.push)]
      end

      if @image
        crumbs << ["Images", admin_images_path]
      end
      
      if @downloadable_asset
        crumbs << ["Files", admin_downloadable_assets_path]
      end
      
      if controller_name == "users" && action_name != "index"
        crumbs << ["Users", admin_users_path]
      end
      
      if @user && !@user.new_record?
        crumbs << [@user.full_name, edit_admin_user_path(@user)]
      end
      
      if @redirect
        crumbs << ["Redirects", admin_redirects_path]
      end
      
      if @donation || @transaction
        crumbs << ["Transactions", admin_transactions_path]
      end

      crumbs.map { |title_and_href| link_to(*title_and_href) }
    end

    def alias_link(redirect, token=nil, html_params=nil)
      query_string = token ? "?t=#{token}" : ''
      if redirect.alias_domain.present?
        link_to "http://#{redirect.alias_domain}#{query_string}", "http://#{redirect.alias_domain}#{query_string}", html_params
      else
        link_to "http://#{request.host_with_port}/#{redirect.alias_path}#{query_string}", "http://#{request.host_with_port}/#{redirect.alias_path}#{query_string}", html_params
      end
    end

    def redirect_name(redirect)
      redirect.alias_path.present? ? redirect.alias_path : redirect.alias_domain
    end

    def admin_main_class
      ['admin/mps', 'admin/senators'].include?(params[:controller])  ? 'mp-editor' : ''
    end

    def mp_attributes
      %W[
        electorate_id
        last_name first_name email
        parliament_phone parliament_fax
        office_address office_suburb office_state
        office_postcode office_fax office_phone
        party_id
      ]
    end

    def senator_attributes
      %W[
        region_id
        last_name first_name email
        state parliament_phone parliament_fax
        office_address office_suburb office_state
        office_postcode office_fax office_phone
        mailing_address mailing_suburb
        mailing_state mailing_postcode
        party_id
      ]
    end

  end
end
