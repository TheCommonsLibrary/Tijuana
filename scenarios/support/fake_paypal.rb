class FakePaypal
  def self.call(env)
    params = Rack::Utils.parse_nested_query(env['rack.input'].read)
    [200, { 'Content-Type' => 'text/html' }, ["<html><body>Fake PayPal is ready to donate $#{params['amount'].to_i} to #{params['item_name']}<div id='params'>{params: {amount: #{params['amount']}, a3: #{params['a3']}, t3: '#{params['t3']}' }}}</div></body></html>"]]
  end
end

Capybara::Server.new(FakePaypal, 8282, Capybara.server_host).boot
