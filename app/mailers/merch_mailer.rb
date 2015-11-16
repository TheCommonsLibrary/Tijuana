class MerchMailer < ActionMailer::Base
  def merchandise_email(csv, supplier_name)
    Rails.logger.info { 'CSV='+csv }
    subject = "#{supplier_name} Merchandise Email"
    attachments['orders.csv'] = {
        :mime_type => 'text/csv',
        :content => csv
    }
    mail(:from => AppConstants.tech_mail_from, :to => 'merch@getup.org.au', :subject => "#{AppConstants.tech_mail_prefix}#{subject}", body: 'See attachment')
  end

  def deliver_merchandise_email(csv, supplier_name)
    merchandise_email(csv, supplier_name).deliver
  end
  handle_asynchronously :deliver_merchandise_email
end
