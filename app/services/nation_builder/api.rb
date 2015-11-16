require 'nationbuilder'

class NationBuilder::Api

  def self.call_api(*args)
    args[2] = {} unless args.third
    args.third[:fire_webhooks] = false
    started_at = DateTime.now
    begin
      payload = get_api_client.call(*args)
      raise_if_empty_payload payload
    rescue NationBuilder::RateLimitedError
      raise
    rescue NationBuilder::ClientError => e
      payload = JSON.parse(e.message)
      raise unless payload_has_a_no_match_code?(payload)
    end
    log_api_call(started_at, payload, *args)
    payload
  end

  private

  def self.get_api_client
    NationBuilder::Client.new NATION_BUILDER[:site], NATION_BUILDER[:api_token], retries: 0
  end

  def self.payload_has_a_no_match_code?(payload)
    payload && payload['code'] == 'no_matches'
  end

  def self.raise_if_empty_payload(payload)
    raise RuntimeError, 'Empty payload returned from NB API - likely due to Rate Limiting' if payload.nil?
  end

  def self.log_api_call(started_at, payload, *call_args)
    NationBuilderSyncLog.create!({
      started_at: started_at, payload: payload, completed_at: DateTime.now,
      source: AppConstants.host, destination: NATION_BUILDER[:site],
      endpoint: call_args[0..1].join('/'), data: call_args.third,
      user_id: call_args.third.try(:[], :person).try(:[], :external_id)
    })
  end
end
