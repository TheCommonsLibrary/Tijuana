class EventPostcodeCache
  class << self

    def fetch(get_together_id, postcode_number, &find_event_proc)
      raise "Missing get together id" if get_together_id.blank?
      raise "Missing postcode" if postcode_number.blank?

      event = nil
      event_id = cache.fetch(key(get_together_id, postcode_number), 
            race_condition_ttl: 10, expires_in: 2.hours) do
              event = find_event_proc.call
              event ? event.id : nil # event id or nil goes in cache
            end

      event || (event_id ? Event.find(event_id) : nil)
    end
    
  private

    def key(get_together_id, postcode_number)
      "EPC1_#{get_together_id}_#{postcode_number}"
    end

    def cache
      Rails.cache
    end
  end
end
