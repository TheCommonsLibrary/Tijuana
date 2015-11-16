require 'net/http'
require 'uri'

class TotalCheckSearchResultIdExpiryException < StandardError
end

class AddressService

  def initialize(uri, username, password)
    @uri = uri
    @username = username
    @password = password
  end

  def lookup_address_using_partial_address(address)
    lookup_address({ formatted_address: address })
  end

  def lookup_address_using_search_result_id(id)
    lookup_address({ search_result_id: id })
  end

  def populate_user_address_from_search_result_id!(user, search_result_id)
    json = full_address_lookup(search_result_id)
    if !json
      raise Exception
    end
    if json['status'] == 'BAD_REQUEST' && json['response_message'].start_with?('Could not locate Search Result for Index')
      raise TotalCheckSearchResultIdExpiryException
    end
    if json['status'] != 'OK' || json['result']['dpid'].blank?
      raise Exception
    end
    update_address(user, json)
  end

  def get_first_search_result_id(address)
    results = lookup_address_using_partial_address(address)
    json = JSON.parse(results)
    json['results'].first['search_result_id']
  end

  private

  def update_address(user, json)
    user.street_address = json['result']['street_address']
    user.suburb = json['result']['suburb']
    user.postcode_number = json['result']['postcode']
    user.address_validated_at = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    user.save!
  end

  def lookup_address(args)
    uri = URI.parse(@uri)
    uri.query = URI.encode_www_form(args)
    response = http_request(uri)
    response.body
  end

  def full_address_lookup(id)
    uri = URI.parse(@uri + '/' + id)
    response = http_request(uri)
    response.code == '200' ? JSON.parse(response.body) : nil
  end

  def http_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.read_timeout = 13
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(@username, @password)
    http.request(request)
  end

end
