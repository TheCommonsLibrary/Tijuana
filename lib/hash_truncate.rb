class HashTruncate
  def self.truncate!(hash, depth, character_limit)
    hash.each_key do |key|
      value = hash[key]
      if depth == 0
        hash[key] = 'ELIDED'
      elsif value.respond_to?(:keys)
        self.truncate!(value, depth-1, character_limit)
      else
        hash[key] = value.to_s.slice(0,character_limit)
      end
    end
  end
end