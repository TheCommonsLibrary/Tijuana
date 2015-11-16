class TokenScanner

  def initialize(text, secure_links=false)
    @scanner = StringScanner.new(text)
    @buffer = StringIO.new
    @last_pos = 0
    @secure_links = secure_links
  end

  def add_tracking_hash_to_links(url_regex, token_regex)
    loop do
      chunk = next_chunk_to_end_of_match(url_regex, token_regex)
      @buffer << chunk   if chunk
      break if finished?
    end
    @buffer.string
  end

  private

  def next_chunk_to_end_of_match(url_regex, token_regex)
    @scanner.scan_until(token_regex)
    pre_text = get_pre_text
    next_chunk = rewrite_pre_text(pre_text, url_regex)
    next_chunk << @scanner.matched if @scanner.matched?
    @last_pos = charpos(@scanner)
    next_chunk.blank? ? remaining_chunk(url_regex) : next_chunk
  end

  def get_pre_text
    if @scanner.matched?
      if (charpos(@scanner) - @scanner.matched.size) <= 0
        ''
      else
        @scanner.string[@last_pos..(charpos(@scanner) - @scanner.matched.size-1)]
      end
    else
      ''
    end
  end

  def rewrite_pre_text(pre_text, url_regex)
    if pre_text.present?
      rewrite_links(pre_text, url_regex)
    else
      ''
    end
  end

  def rewrite_links(text, regex)
    text.gsub(regex) do |match|
      sub = match.index('?') ? "#{match}&t={TRACKING_HASH|NOT_AVAILABLE}" : "#{match}?t={TRACKING_HASH|NOT_AVAILABLE}"
      sub = sub + "&secure_token={SECURE_TOKEN|NOT_AVAILABLE}" if @secure_links
      sub
    end
  end

  def remaining_chunk(regex)
    chunk = @scanner.string[charpos(@scanner)..-1]
    chunk = rewrite_links(chunk, regex) if chunk
    chunk
  end

  def finished?
    return @scanner.eos? || !@scanner.matched?
  end

  def charpos(string_scanner)
    string_scanner.string.byteslice(0, string_scanner.pos).length
  end
end
