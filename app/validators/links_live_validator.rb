require 'net/http'
require 'set'
class LinksLiveValidator < ActiveModel::EachValidator
  def self.validate_each(record, attribute, value)
    Nokogiri::HTML(value).css('a').each do |a|
      href = a.attribute('href').try(:text)
      if href
        begin
          url = URI.parse(href)
          if ['http', 'https'].include?(url.scheme) and !is_url_reachable?(url)
            record.errors.add(attribute, "Link '#{href}' cannot be resolved to a valid website.")
            return false
          end
        rescue URI::InvalidURIError => e
          record.errors.add(attribute, "Link '#{href}' is not a well formed URI")
          return false
        end
      end
    end
  end

  def self.is_url_reachable?(url, limit = 5)
    return false if limit == 0   
    uri = URI(url)
    return true if Rails.env.development? && uri.host == AppConstants.host
    begin
      response = Net::HTTP.start(uri.host, 
        use_ssl: uri.scheme == 'https') do |http|
        http.get uri.request_uri, 'User-Agent' => 'MyLib v1.2'
      end
    rescue 
      false
    end
  
    case response
      when Net::HTTPSuccess then
        true
      when Net::HTTPRedirection then
        location = response['location']
        is_url_reachable?(location, limit - 1)
      else
        false  
    end
  end
end
