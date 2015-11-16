class ActivityController < ApplicationController
  caches_action :show, :expires_in => 30.seconds, :if => Proc.new { |c| c.request.format.json? }
  EVENT_COUNT = 20

  def show
    events = UserActivityEvent.where(:activity => 'action_taken').
      where("updated_at > ?", Date.yesterday).
      where("public_stream_html not like '%>a cause</a>.'"). # remove imported donations which don't have valid pages
      where('public_stream_html is not null').
      where("public_stream_html not like ''").
      where("source is null OR source not like 'cr_%'").
      order('updated_at desc').
      limit(EVENT_COUNT)
    
    stream = events.map do |event|
      {
        :id => event.id,
        :html => event.public_stream_html,
        :timestamp => event.created_at.httpdate
      }
    end
    respond_to do |format|
      format.json { render :json => stream }
    end
  end
end
