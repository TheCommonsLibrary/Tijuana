class MergeToken
  def self.valid_token?(token)
    valid_eval?(get_eval(token))
  end

  def self.valid_eval?(merge_eval)
    merge_eval.match(/^merge\('[^']*',\s*'[^']*'\)$/) ||
    whitelist_merge_tokens.include?(merge_eval)
  end

  def self.whitelisted?(key)
    whitelist_merge_tokens.include?(key)
  end

  def self.get_eval(token)
    token.gsub(/^MERGE:/, '')
  end

private
  def self.whitelist_merge_tokens
    remove_comments(Setting[:whitelist_merge_tokens] || '')
  end
  
  def self.remove_comments(whitelist)
    whitelist.split("\n").map{|i| i.gsub(/#.*/,'')}.map(&:strip)
  end
end
