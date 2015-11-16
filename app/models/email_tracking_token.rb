class EmailTrackingToken
  def self.encode(user_id, email_id)
    hashids.encode(user_id, email_id)
  end

  def self.encode_with_source(source_id)
    hashids.encode(0, 0, source_id)
  end

  def self.decode(token_string)
    return {} if token_string.blank?
    token_string.gsub!(/\s+/, "")

    ids = if token_string.starts_with?('d')
      legacy_decode(token_string)
    else
      hashids.decode(token_string)
    end

    ids_as_hash(ids)
  rescue StandardError => e
    Rails.logger.error("token didn't decode: #{token_string}; #{e}; #{e.backtrace.first}")
    {}
  end

private

  def self.legacy_decode(token_string)
    decoded = Base64.urlsafe_decode64(token_string)
    m = decoded.match(/^userid=(?<userid>\d+),emailid=(?<emailid>\d+)$/)
    m ? [m[:userid].to_i, m[:emailid].to_i] : []
  end

  def self.ids_as_hash(ids)
    return {} if ids.size < 2
    ids_hash = {userid: ids[0], emailid: ids[1]}
    if ids[2]
      ids_hash[:sourceid] = ids[2]
    end
    ids_hash
  end

  MIN_HASH_LENGTH = 0
  ALPHABET = ([*'0'..'9',*'A'..'Z',*'a'..'z'] - ['d']).join
  def self.hashids
    Hashids.new(AppConstants.email_token_salt, MIN_HASH_LENGTH, ALPHABET)
  end

end
