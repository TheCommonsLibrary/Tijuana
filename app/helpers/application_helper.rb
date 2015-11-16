module ApplicationHelper
  include EmailFormatHelper

  def humanized_error_message_for_field(field_symbol, model_error_message, html_safe = false)
    field_name = field_symbol == :base ? nil : field_symbol.to_s.humanize
    error_message = model_error_message
    if model_error_message.start_with?('^')
      error_message = model_error_message[1..-1]
      field_name = nil
    end
    message = "#{field_name} #{error_message}".lstrip
    html_safe ? message.html_safe : message
  end

  def all_error_messages_for_field(field_symbol, error_messages)
    error_messages.collect {|msg| humanized_error_message_for_field(field_symbol, msg) }.
                   join(" and ")
  end

  def include_jquery
    javascript_include_tag 'common/lib/jquery.min', 'common/lib/jquery-ui'
  end

  def include_addthis
    unless Rails.env.test?
      context = params[:exp] ? "daisy-#{params[:exp]}" : "tellafriend"
      html = javascript_include_tag("#{request.protocol}s7.addthis.com/js/300/addthis_widget.js#username=getupaustralia")
      html += javascript_tag """
        $(function(){
          function shareHandler(event) {
            var token = btoa(JSON.stringify({name: 'share-' + event.data.service, context: '#{context}'}));
            $.get('/event/' + token + '/beacon.gif');
          }

          addthis.addEventListener('addthis.menu.share', shareHandler);
        });
      """
      html
    end
  end

  def include_facebook_like_from_theme(theme, color_scheme, layout)
    unless Rails.env.test?
      settings = customise_settings_from_theme(theme, color_scheme)
      # We use iframe explicitly as addthis or other facebook api calls do not support responsive facebook standard like buttons.
      # Here we can control the overflow and cause the like button iframe to change size responsively.
      js = <<-JS
        $(function() {
          var facebookLikeATag = "<iframe class='gu-fb-like' src='//www.facebook.com/plugins/like.php?app_id=213604462004694&amp;href=#{settings[:href]}&amp;send=false&amp;layout=#{layout}&amp;width=450&amp;show_faces=false&amp;action=like&amp;colorscheme=#{settings[:color_scheme]}&amp;font&amp;height=30' scrolling='no' frameborder='0' style='border:none; overflow:hidden; width:100%; height:40px;' allowTransparency='true'></iframe>";
          $("#action .fb-like-above").before(facebookLikeATag);
        });
      JS
      javascript_tag js
    end
  end

  def customise_settings_from_theme(theme, color_scheme)
    if theme
      community_run_theme_id = 2
      return {color_scheme: 'light', href: 'http://www.facebook.com/communityrun'} if theme.id == community_run_theme_id
    end
    {color_scheme: color_scheme, href: 'http://www.facebook.com/GetUpAustralia'}
  end

  private :customise_settings_from_theme

  def render_nav_bar?(page)
    return true if params[:controller] && params[:controller].start_with?('admin')
    if page
      return !campaign_ask_page?(page)
    else
      true
    end
  end

  def campaign_ask_page?(page)
    !page.static? && page.has_an_ask?
  end

  def form_errors(subject)
    if params[:controller].try :start_with?, 'admin'
      render :partial => "common/admin_form_errors", :locals => {:subject => subject}
    else
      render :partial => "common/form_errors", :locals => {:subject => subject}
    end
  end

  def friendly_path(page, params={})
    campaign_id = page.page_sequence.campaign ? page.page_sequence.campaign.friendly_id : nil
    page_path(campaign_id, page.page_sequence.friendly_id, page.friendly_id, params)
  end

  def friendly_url(page)
    campaign_id = page.page_sequence.campaign ? page.page_sequence.campaign.friendly_id : nil
    page_url(campaign_id, page.page_sequence.friendly_id, page.friendly_id)
  end

  def friendly_url_from_page_sequence(page_sequence)
    campaign_id = page_sequence.campaign ? page_sequence.campaign.friendly_id : nil
    page_url(campaign_id, page_sequence.friendly_id)
  end

  def word_truncate(text, length = 30, truncate_string = "...")
    return if text.nil?
    l = length - truncate_string.length
    text.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end

  def sum_list objects, m
    objects.inject(0) { |acc, t| acc += t.send(m); acc }
  end

  def substitute_real_cdn_url(content)
    if S3[:enabled]
      real_cdn_url = "#{request.protocol}#{S3[:cdn_host]}"
    else
      real_cdn_url = "#{request.protocol}#{request.host_with_port}/system"
    end

    content.gsub(/(http[s]?:\/\/)?#{S3[:token_cdn_host]}/, real_cdn_url)
  end

  def render_html(content)
    return "" if content.blank?
    html = substitute_real_cdn_url(content)

    if request.ssl?
      html.gsub!('src="http:', 'src="https:')
    end

    html += '<div class="content-end"></div>'
    return html
  end

  def body_class(additional_classes=nil)
    # this should be pulled into the controller as a virtual method
    if controller.instance_of?(HomeController) || controller.instance_of?(UnsubscribeController) || controller.instance_of?(EventsController) || controller.instance_of?(GetTogethersController)
      "article"
    elsif @page
      classes = "article"
      classes += " action" if @page.has_an_ask?
      classes += " campaign" if campaign_ask_page?(@page)
      classes += " aside" if @page.valid_aside_content_modules.present?
      classes += " #{additional_classes.join(' ')}" if additional_classes
      classes
    else
      "home has_navbar article" # dashboard
    end
  end

  def body_id
    if controller.instance_of? HomeController
      "home"
    elsif @page && @page.has_an_ask?
      case @page.ask_module.type
        when "CallMPModule"
          "call"
        when "EmailMPModule", "EmailTargetsModule", "TargetListModule", "EmailPledgesModule"
          "email"
        when "DonationModule", "MerchModule", "DonationUpgradeModule", "ImageShareModule"
          "donation"
        else
          "petition"
      end
    else
      nil
    end
  end

  def active_class(url)
    request.fullpath == url ? "active" : nil
  end

  def page_title(organisation_name="GetUp!")
    content_for?(:title) ? "#{organisation_name} - #{content_for :title}" : AppConstants.default_page_title
  end

  def page_header_title
    content_for?(:title) ? "#{content_for :title}" : nil
  end

  def reset_password_url(url)
    match = url.match(/^(.*\/\/)?(www\.)?(.*)$/)

    if Rails.env.production?
      "https://www.#{match[3]}"
    elsif Rails.env.showcase?
      "https://#{match[3]}"
    else
      match[3]
    end
  end

  def field_errors(object, field)
    render :partial => "common/field_errors", :locals => {:object => object, :field => field}
  end
  
  def rails_session_id
    request.session_options[:id] rescue nil
  end
end
