module SendgridSupport

  def to_json_for_sendgrid(email_headers)
    JSON.generate(email_headers, {array_nl: ' '})
  end

  def reject_unsafe_email_addresses(email_addresses)
    if !["test", "production"].include?(Rails.env)
      email_addresses.reject { |email_address| !(email_address =~ /emailtests.com|getup.org.au/) }
    else
      email_addresses
    end
  end
end
