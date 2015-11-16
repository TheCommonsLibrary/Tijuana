class Utf8Encoder
  def self.clean_to_utf8(log)
    hash = {}
    log.each do |key, value|
      if value.is_a?(Hash)
        hash[key] = clean_to_utf8(log[key]) 
      else
        clean_value = clean_string(value)

        if key.is_a?(String)
          clean_key = clean_string(key)
          hash[clean_key] = clean_value
        else
          hash[key] = clean_value
        end
      end
    end
    hash
  end

private

  def self.clean_string(string)
    if string.is_a?(String)
      string.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?') 
    else
      string
    end
  end
end
