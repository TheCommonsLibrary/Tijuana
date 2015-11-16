module Admin
  class DashboardController < AdminController
    skip_authorize_resource
    skip_authorization_check
    skip_before_filter :authenticate_admin!, :only => [:latest_emails]

    def index
      @pages = Page.includes(:page_sequence => :campaign).where("updated_at >= ?", 7.days.ago).order('updated_at DESC')
      @sent_emails = SentEmail.includes(:email => {:blast => {:push => :campaign}}).where("created_at >= ?", 7.days.ago).order('created_at DESC')
    end

    def latest_emails
      if current_user.email == 'getupbuildbox@gmail.com'
        sql = 'select emails.* from emails left outer join sent_emails on emails.id = sent_emails.email_id
               where emails.test_sent_at is not null and sent_emails.email_id is null limit 6'
        @proofed_emails = Email.find_by_sql(sql, :include => {:blast => {:push => :campaign}})
        @sent_emails = SentEmail.includes(:email => {:blast => {:push => :campaign}}).order('created_at DESC').limit(6).all
        render :layout => 'themes/no_branding'
      else
        head(403)
      end
    end
  end
end
