class BeaconController < ApplicationController
  def send_beacon_gif
    expires_now
    send_data(Base64.decode64("R0lGODlhAQABAPAAAAAAAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw=="), :type => "image/gif", :disposition => "inline")
  end

  def index
    token = TrackingTokenLookup.new(params['t'])
    if token.valid?
      @token_user = token.user
      UserActivityEvent.email_viewed!(@token_user, token.email)
    end
    send_beacon_gif
  end

  def track_email_target
    id = EmailTargetTrackingLog.decode_token(params[:t])
    if user_email = UserEmail.find_by_id(id)
      EmailTargetTrackingLog.create!({
        user_email: user_email,
        referrer: request.referrer,
        agent: request.user_agent,
        ip: request.remote_ip
      })
    end
    send_beacon_gif
  end

  def track_event
    if user_id = cookies[:user_track]
      data = begin JSON.parse(Base64.decode64(params[:t].to_s)) rescue {} end
      if data['name']
        EventTrackingLog.create!({
          user_id: user_id,
          name: data['name'],
          context: data['context'],
          referrer: request.referrer,
          agent: request.user_agent,
          ip: request.remote_ip
        })
      end
    end
    send_beacon_gif
  end
end
