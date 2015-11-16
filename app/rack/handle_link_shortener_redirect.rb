class HandleLinkShortenerRedirect


  def initialize(app)
    @app = app
    @link_shortener_domain = AppConstants.link_shortener_domain
    @salt = AppConstants.link_shortener_salt
  end

  def call(env)
    @protocol = env['rack.url_scheme']
    url = env['SERVER_NAME'] + env['PATH_INFO']
    hash = hash_from_link_shortened_url(url)
    if hash
      ExceptionNotifier.rescue_and_mail_tech(env, true) do
        decoded_ids = hash_ids.decode(hash) # failed decode returns empty array
        target = decoded_ids.present? ? build_target(*decoded_ids) : root_url
        return [302, {"Location" => target}, ['Redirecting...']]
      end
    else
      @app.call(env)
    end
  end

  private

  def hash_from_link_shortened_url(url)
    match_data = url.match(/^(www\.)?#{@link_shortener_domain}\/([A-z,0-9]+)$/)
    match_data ? match_data.captures.last : nil
  end

  def build_target(user_id, email_id, page_id, redirect_id)
    token = EmailTrackingToken.encode(user_id,email_id)
    token_string = TrackingTokenLookup.new(token).valid? ? "?t=#{token}" : ''
    redirect = Redirect.find_by_id redirect_id
    campaign, page_sequence, page = get_page_details(page_id) if redirect.nil?

    if redirect
      return redirect.target + token_string
    elsif page
      return "#{root_url}/campaigns/#{campaign.id}/#{page_sequence.id}/#{page.id}#{token_string}" if campaign
      return "#{root_url}/#{page_sequence.id}/#{page.id}#{token_string}"
    else
      return root_url
    end
  end

  def get_page_details(id)
    page = Page.find_by_id(id)
    page_sequence = !page.nil? ? page.page_sequence : nil
    campaign = !page_sequence.nil? ? page_sequence.campaign : nil
    return campaign, page_sequence, page
  end

  def hash_ids
    @hash_ids ||= Hashids.new(@salt)
  end

  def root_url
    "#{@protocol}://#{AppConstants.host}"
  end
end
