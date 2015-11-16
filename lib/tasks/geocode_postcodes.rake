require "net/http"
require 'net/https'
require "uri"
require 'nokogiri'
require 'csv'

POSTCODE_PREFIX = 'http://post-code.net.au/postcode/'
GOOGLE = 'https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address='
postcodes = ['0834', '0839', '0853', '0885', '2174', '2818', '2826', '3213', '3234', '3374', '3433', '3477', '3578', '3662', '3698', '3761', '3762', '3920', '3940', '4813', '4892', '5090', '5151', '5220', '5312', '5653', '5701', '6077', '6078', '6079', '6181', '6572', '6625', '6761', '7139', '7174', '7183', '8500', '8507', '8538', '8557', '8622', '8626', '8785', '8865']

res = {}

def https(prefix, data)
  uri = URI.parse("#{prefix}#{data}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(uri.request_uri)
  http.request(request)
end

def call(prefix, data)
  uri = URI.parse("#{prefix}#{data}/")
  Net::HTTP.get_response(uri)
end

def geocode(node, postcode, csv)
  state = node[0].xpath('text()').to_s.gsub(/[( )]/,'')
  suburb = node[0].xpath('a/text()').to_s
  puts "#{postcode} = #{suburb}, #{state}"
  response = https(GOOGLE, "#{suburb} #{state} #{postcode} Australia".gsub(' ','+'))
  json = JSON.parse(response.body)
  if json['results'][0]
    lat = json['results'][0]['geometry']['location']['lat']
    long = json['results'][0]['geometry']['location']['lng']
    csv << [postcode, lat, long]
  else
    puts "No results for: #{postcode}"
  end
end

desc 'script hacked up to look up suburb and state on post-code.net.au and uses that to make a geocode request to google.'
task 'geocode_postcode_number' do
  CSV.open('outfile.csv', 'w') do |csv|
    postcodes.each do |postcode|
      response = call(POSTCODE_PREFIX, postcode)
      html_doc = Nokogiri::HTML(response.body)
      suburb = html_doc.xpath('/html/body/div/div/table/tr/td/ul/li[1]')
      if suburb.present?
        res[postcode] = geocode(suburb, postcode, csv)
      end
    end
  end

  #puts res.inspect

end
