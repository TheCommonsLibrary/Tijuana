class CanonicalRedirect

  def initialize(app, host=nil, &block)
    @app = app
    @canonical_uri = AppConstants.host
    @redirect_domains = AppConstants.redirect_domains
    @need_redirect = !@redirect_domains.blank?
  end

  def call(env)
    redirect = redirect_url(env)
    if redirect
      [301, {'Location' => redirect}, ['Redirecting...']]
    else
      @app.call(env)
    end
  end

  def redirect_url(env)
    incoming_domain = env['SERVER_NAME']
    if @need_redirect && @redirect_domains.include?(incoming_domain)
      Rack::Request.new(env).url.gsub(incoming_domain, @canonical_uri)
    end
  end
  private :redirect_url
end
