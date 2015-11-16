require 'active_support'

class CallOutcomeService

  def process(params)
    attrs = params.slice(
      :id,
      :email,
      :campaign_code,
      :campaign_type,
      :njAllocationName,
      :njCallDate,
      :njCallDuration,
      :njCampaignName,
      :njDialAttempts,
      :njDialedNumber,
      :njDisposition,
      :njUniqueCallId,
    )

    {
      received_at: Time.now,
      call_date: attrs[:njCallDate],
      user_id: attrs[:id].present? ? attrs[:id].to_i : nil,
      email: attrs[:email],
      unique_call_id: attrs[:njUniqueCallId],
      disposition: attrs[:njDisposition],
      campaign_type: attrs[:campaign_type],
      campaign_code: attrs[:campaign_code],
      campaign_name: attrs[:njCampaignName],
      allocation_name: attrs[:njAllocationName],
      dialed_number: attrs[:njDialedNumber],
      dial_attempts: attrs[:njDialAttempts].to_i,
      call_duration: attrs[:njCallDuration].to_i,
      payload: params.to_json,
    }
  end

end
