module InlineTokenReplacement

  private
  
  # Rick, 2011-02-17: Benchmarked at 1 second per 10k emails with three tokens
  def replace_tokens(text, tokens)
    tokens.each do |token, replacement|
      matches = with_optional_default(token).match(text)
      to_be_replaced, default = *matches
      text = replace(text, to_be_replaced, replacement, default)
    end
    text
  end
  
  def with_optional_default(token)
    /{#{token}\|?([^}]*)}/
  end
  
  def replace(text, to_be_replaced, replacement, default)
    return text if to_be_replaced.blank?
    if replacement.is_a?(Proc)
      replacement = replacement.call(default)
    elsif replacement.blank?
      replacement = default
    end
    text.gsub(to_be_replaced, replacement)
  end
end
