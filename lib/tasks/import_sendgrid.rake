require 'open-uri'
require 'json'

namespace :import do
  namespace :sendgrid do

    desc "Import bounce, spam and invalid emails data from SendGrid and mark matching members as unsubscribed"
    task :drops => :environment do
      getSendgridAPI('bounces').each{|info| unsubscribe('bounce', info) }
      getSendgridAPI('invalidemails').each{|info| unsubscribe('invalid', info) }
      getSendgridAPI('spamreports').each{|info| unsubscribe('spam', info) }
    end

    def getSendgridAPI(action)
      url = get_api_url(action)
      data = JSON.parse(OpenURI.open_uri(url).read)
      Rails.logger.info "Retrieved #{data.length} #{action.gsub(/emails|reports/, ' reports')} from SendGrid.."
      data
    end

    def get_api_url(action)
      auth = get_sendgrid_auth
      api = "https://api.sendgrid.com/api/#{action}.get.json?"
      params = {api_user: auth['user'], api_key: auth['key'], date: 1}
      if ENV['FROM'] || ENV['TO']
        params['start_date'] = ENV['FROM'] if ENV['FROM']
        params['end_date'] = ENV['TO'] if ENV['TO']
      elsif !ENV['ALL']
        params['start_date'] = 10.days.ago.to_date.to_s
      end
      params['type'] = 'hard' if action == 'bounces'
      Rails.logger.info("API call #{api + params.to_query}")
      api + params.to_query
    end

    def unsubscribe(reason, sendgrid_info)
      # Don't unsubscribe for certain temporary bounce reasons
      return if reason == 'bounce' and is_temportary_bounce?(sendgrid_info['reason'])
      user = User.subscribed.find_by_email(sendgrid_info['email'])
      if user
        dropped_at = DateTime.parse(sendgrid_info['created']) 
        Rails.logger.info "Dropping #{user.email} at #{dropped_at}"
        ActiveRecord::Base.transaction do
          user.update_attribute(:is_member, false)
          UserActivityEvent.email_dropped_unless_duplicate_event!(user, reason, dropped_at)
        end
      end
    end

    def get_sendgrid_auth
      if defined? SENDGRID_CONFIG
        config = SENDGRID_CONFIG[Rails.env]
        { 'user' => config['username'], 'key' => config['password'] }
      else
        {}
      end
    end

    def is_temportary_bounce?(reason)
      return false if reason.blank?
      # DMARC rejection from yahoo
      reason.match(/Message not accepted for policy reasons/) ||
      # Mailbox is temporarily full
      reason.match(/mailbox[ is]*full/i)
    end

  end
end
