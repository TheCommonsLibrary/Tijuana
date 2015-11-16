require_relative '../../lib/exception_notifier_rescue_and_mail_tech'

class HandleConfigurableRedirect

  TOP_LEVEL = /^\/[^\/]+$/ #eg. /climate

  def initialize(app)
    @app = app
    @canonical_uri = AppConstants.host
    @expected_hosts = [@canonical_uri] + AppConstants.cloaked_domains.constants_hash.keys
  end

  def call(env)
    path = env['PATH_INFO']
    ExceptionNotifier.rescue_and_mail_tech(env, true) { track_click(env) if should_track_click?(env) }
    sanitise_query_string(env) if @sanitise_query_string
    if (path =~ TOP_LEVEL) || (env['SERVER_NAME'] != @canonical_uri)
      redirect = check_for_redirect(env)
      return redirect if redirect
    end
    @app.call(env)
  end

  private

  def sanitise_query_string(env)
    # replace incomplete percent encoded characters with encoded percent character
    env['QUERY_STRING'] = env['QUERY_STRING'].gsub(/%(?![0-9a-fA-F]{2})/, '%25')
  end

  def track_click(env)
    params = safe_parse_nested_query(env['QUERY_STRING'])
    token = TrackingTokenLookup.new(params['t'])
    if token.valid?
      UserActivityEvent.email_clicked!(token.user, token.email)
    end
  end

  def safe_parse_nested_query(query)
    Rack::Utils.parse_nested_query(query)
  rescue ArgumentError => e
    # Ruby's URI.encode_www_form_component raises if our old tokens are incomplete
    @sanitise_query_string = true if e.message =~ /invalid %-encoding/
    return {}
  end

  def should_track_click?(env)
    exclusions = /^\/(beacon.gif|unsubscribe)/
    path = env['PATH_INFO']
    env['REQUEST_METHOD'] == 'GET' && path !~ exclusions
  end

  def check_for_redirect(env)
    redirect = get_redirect(env)
    if redirect
      target = Redirect.merge_query_string(redirect.target, env["QUERY_STRING"])
      return [302, { "Location" => target }, ['Redirecting...']]
    end
  end

  def get_redirect(env)
    if !@expected_hosts.include?(env["SERVER_NAME"])
      Redirect.find_by_alias_domain(env["SERVER_NAME"])
    else
      Redirect.find_by_alias_path(env["PATH_INFO"].sub("/", ""))
    end
  end
end
