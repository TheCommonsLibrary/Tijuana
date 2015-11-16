host = ENV['ADDRESS_SERVICE_HOST']
user = ENV['ADDRESS_SERVICE_USER']
pass = ENV['ADDRESS_SERVICE_PASS']

ADDRESS_SERVICE = AddressService.new(host, user, pass)
