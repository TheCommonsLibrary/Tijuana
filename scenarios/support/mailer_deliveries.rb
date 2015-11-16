module EmailSpec
  module MailerDeliveries
    def sent_addresses(email)
      [email.to, email.cc, email.bcc, email.header['X-SMTPAPI'] && JSON.parse(email.header['X-SMTPAPI'].value)['to']].compact.flatten
    end
    
    def mailbox_for(address)
      deliveries.select do |email|
        sent_addresses(email).include?(address)
      end
    end
  end
  
  module Helpers
    def set_current_email(email)
      return unless email
      sent_addresses(email).each do |to|
        read_emails_for(to) << email
        email_spec_hash[:current_emails][to] = email
      end
      email_spec_hash[:current_email] = email
    end
  end
end