class ApiController < ApplicationController
  include PagePathModule
  include VisionSurveyModule

  before_filter :http_basic_authentication, :only => [:users]
  before_filter :authenticate_api_token!, :only => [:tag_emails]
  before_filter :cors, only: [:page_sequences, :transparency_stats]
  skip_before_filter :verify_authenticity_token
  caches_action :electoral_target, expires_in: 1.hour, cache_path: Proc.new { |c| c.params  }
  
  respond_to :xml, :json

  # for csg.getup.org.au flash app
  def csg_petition_signature_count
    render :text => PetitionSignature.where(:content_module_id=>1392).count
  end

  # CR webhook
  def users
    begin
      users_unsafe
    rescue Exception => e
      ExceptionNotifier.notify_exception(e, env: request.env)
      render :text => e.to_s, :status => 500
    end
  end

  def take_action_with_fb
    ask = ContentModule.find(params[:module_id].to_i)
    page = Page.find(params[:page_id])
    tracking_token = TrackingTokenLookup.new(params[:t])
    email = tracking_token.email
    acquisition_source = tracking_token.acquisition_source
    user = populate_or_initialise_user(params.slice(:email, :first_name, :last_name, :suburb, :facebook_id))

    subscribed = user.did_subscribe_during? do
      user.save_with_source_info!(page, ask, email, 'facebook', acquisition_source)
    end
    if subscribed
      UserMailer.welcome_to_getup(user) if !page.welcome_email_disabled? && !page.quarantined?
      user.quarantine!(email: email, page: page) if page.quarantined?
    end

    ask.take_action(user, page, email, nil, {source: 'facebook', acquisition_source: acquisition_source})
    FacebookUser.find_or_create_by_user_id_and_facebook_id(user.id, params[:facebook_id])
    ThankyouEmail.new(page, user, ask).send! if page.send_thankyou_email?

    head :ok, location: next_page_path(page)
  rescue DuplicateActionTakenError, ActiveRecord::RecordNotUnique
    head :ok, location: next_page_path(page)
  end

  def tag_emails
    unless params[:tag].present? && params[:emails].present?
      render json: {status: "Rejected", reason: "Missing params"}, status: 400
      return
    end
    unless params[:tag].length <= 255
      render json: {status: "Rejected", reason: "Tag max length is 255"}, status: 400
      return
    end
    unless params[:emails].length <= 1000
      render json: {status: "Rejected", reason: "Max 1000 emails may be submitted at once. Batch your calls if you have more"}, status: 400
      return
    end

    User.where(email: params[:emails]).add_tags([params[:tag]])
    render json: {status: "Accepted"}
  end

  def page_sequences
    unless Campaign.valid_accounts_key?(params[:pillar])
      render json: {status: "Rejected", reason: "invalid key"}, status: 400
      return
    end
    render json: PageSequence.pillared(params[:pillar]).pillar_visible
  end

  def transparency_stats
    render json: Stats::TransparencyStats.new.load
  end

  def electoral_target
    jurisdiction = params[:jurisdiction]
    unless params[:postcode].present? && jurisdiction.present?
      render json: {status: "Rejected", reason: "Missing params"}, status: 400
      return
    end
    postcode = Postcode.find_by_number(params[:postcode])
    unless postcode
      render json: {status: "Rejected", reason: "No Matching Postcode"}, status: 400
      return
    end
    if params[:parties]
      parties = Party.find_all_by_abbreviation(params[:parties])
      if parties.empty?
        render json: {status: "Rejected", reason: "No Matching Party"}, status: 400
        return
      end
    end
    mps_with_senator_fallback = postcode.electorates.most_likely_by_jurisdiction(jurisdiction)
      .map{|electorate|
        if mp_for_target_party = parties ? electorate.mps.find{|mp| parties.include?(mp.party) } : electorate.mps.first
          { electorate: electorate.name, representative: mp_for_target_party }
        elsif region_with_matching_senator = postcode.regions.by_jurisdiction_party(jurisdiction, parties).first
          matching_senators = region_with_matching_senator.senators.select{|senator|
            parties.empty? || parties.include?(senator.party)
          }
          { electorate: electorate.name, representative: matching_senators.sample}
        end
      }.compact
    render json: mps_with_senator_fallback, each_serializer: RepresentativeApiSerializer
  end

  private

  def populate_or_initialise_user(attributes)
    user = User.find_or_initialize_by_email(attributes['email'])
    user.assign_attributes(attributes.select { |k,v| !v.blank? && user.send(k).blank? })
    user
  end

  def users_unsafe
    data = JSON.parse(params["data"])
    user = User.find_by_email(data["email"])
    agra_action = nil
    create_action = Proc.new { agra_action = AgraAction.new(user_id:user.id, slug:data["slug"], role:data["role"], source:data["source"].try(:[], 0...100)); agra_action.save! }
    tracking_token = TrackingTokenLookup.new(data['t'])

    if user.nil?
      postcode = Postcode.find_by_number(data["postcode"]) ? Postcode.find_by_number(data["postcode"]) : nil
      user = User.new(:first_name => data["first_name"], :last_name => data["last_name"], :email => data["email"],
                      :postcode => postcode, :mobile_number => data["phone_number"])

      if user.valid?
        categories = data['categories']
        source = 'cr'
        user.save_with_source_info! nil, nil, nil, source, tracking_token.acquisition_source, community_run_categories: categories
        warehouse_data(user_id: user.id)
        send_agra_welcome_email(user)
        status = 201
        create_action.call
        if Setting.quarantined_controlshift_slugs.include?(data['slug'])
          user.quarantine!(source: source, agra_action: agra_action)
        end
        record_user_activity_event user, tracking_token, agra_action
      else
        status = 400
      end
    else
      status = 200
      create_action.call
      warehouse_data(user_id: user.id)
      record_user_activity_event user, tracking_token, agra_action
      resubscribe(user)
    end
    render :json => user.errors.to_json, :status => status
  end

  def resubscribe(user)
    user.is_member = user.is_agra_member = true
    user.save!(validate: false)
  end

  def send_agra_welcome_email(user)
    UserMailer.welcome_to_community_run(user)
  end

  def http_basic_authentication
    authenticate_or_request_with_http_basic do |username, password|
      username == 'api' && password == '8hsFCogjQfFZ'
    end
  end

  def record_user_activity_event(user, token, agra_action)
    warehouse_data({token_user_id: token.user.try(:id), email_id: token.email.try(:id)})
    UserActivityEvent.agra_take_action! user, token.email, agra_action, token.acquisition_source
  end

  def cors
    return unless request.headers['origin'] =~ /https?:\/\/([\w\.-]+):?(\d{4})?\/?/
    domain = $~[1]
    if allowed_origins.any?{|o| o == domain }
      headers['Access-Control-Allow-Origin'] =  request.headers['origin']
      headers['Access-Control-Request-Method'] = 'GET'
      headers['Vary'] = 'Origin'
    end
  end

  def allowed_origins
    [
      'getup.org.au',
      'www.getup.org.au',
      'showcase.getup.org.au',
      'legit-raven.cloudvent.net', # CloudCannon preview site
      'app.cloudcannon.com',
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
    ]
  end
end
