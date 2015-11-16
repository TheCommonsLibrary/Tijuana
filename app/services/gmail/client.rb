require 'google/apis/gmail_v1'
GmailApi = Google::Apis::GmailV1 unless defined?(GmailApi)

class Gmail::Client

  def self.get_client(account)
    client = GmailApi::GmailService.new
    authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.modify'])
    auth_client = authorization.dup
    auth_client.sub = "#{account}@getup.org.au"
    auth_client.fetch_access_token!
    client.authorization = auth_client
    client
  end
end
