sandbox_config_file = File.join(Rails.root, 'config', 'paypal-sandbox.yml')
if File.exists?(sandbox_config_file)
  sandbox_config = YAML.load_file(sandbox_config_file)
  PayPalSandbox = sandbox_config[Rails.env] if sandbox_config[Rails.env]
end
