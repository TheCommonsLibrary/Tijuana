class NoNakedLinksValidator < ActiveModel::EachValidator
  URL_PREFIXES = /http[^\s]*|www\.[^\s]*/
  NAME_REGEX = /https?:\/\/(?:www\.)?([^\.]*)/

  def validate_each(record, attribute, value)
    Nokogiri::HTML(value).search('//text()').find_all do |e|
      if e.parent.name != 'a' && e.parent.name != 'style' && !e.text.match(/MERGE:/)
        e.text.scan(URL_PREFIXES) do |match|
          url = match.start_with?("http") ? match : "http://#{match}"
          name = url.scan(NAME_REGEX).flatten.first || match
          record.errors.add(attribute, "contains naked link to '#{match}'. It should be enclosed in an anchor tag such as <a href=\"#{url}\">#{name.humanize}</a>")
        end
      end
    end
  end

end
