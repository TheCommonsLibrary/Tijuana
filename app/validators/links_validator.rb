class LinksValidator < ActiveModel::EachValidator
  NO_WHITESPACE_REGEX = /^[^\s]+$/
  VALID_PROTOCOL_OR_MERGE_TOKEN_REGEX = /^(http|https|mailto|{MERGE):/
  def validate_each(record, attribute, value)
    Nokogiri::HTML(value).css('a').each do |a|
      if a.attribute('href')
        href = a.attribute('href').text
        record.errors.add(attribute, "Anchor tag: '#{href}' cannot have whitespace present in href attribute.") unless NO_WHITESPACE_REGEX.match(href)
        record.errors.add(attribute, "Anchor tag: '#{href}' href attribute can only be 'http://', 'https://' or 'mailto:'") unless VALID_PROTOCOL_OR_MERGE_TOKEN_REGEX.match(href)
      else
        record.errors.add(attribute, "Anchor tag: '#{a}' must have an href attribute present. If an href exists, make sure it's correctly formed eg <a href='http://www.google.com/'>Google</a>")
      end
    end
  end
end
