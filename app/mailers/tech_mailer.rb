class TechMailer < ActionMailer::Base
  def weekly_statistics_email(to, subject, weekly_stats)
    @weekly_stats = weekly_stats
    mail(:from => AppConstants.tech_mail_from, :to => to, :cc => AppConstants.tech_mail_to, :subject => subject, :content_type => "text/html")
  end

  def donation_monitor_warning_email(overdue_donations, overdue_by_description)
    @overdue_donations = overdue_donations
    @overdue_by_description = overdue_by_description
    mail(:from => AppConstants.tech_mail_from, :to => AppConstants.tech_mail_to, :subject => "#{AppConstants.tech_mail_prefix}Donation Monitor Warning", :content_type => "text/html")
  end

  def warning_email(subject, body)
    mail(:from => AppConstants.tech_mail_from, :to => AppConstants.tech_mail_to, :subject => "#{AppConstants.tech_mail_prefix}#{subject}", :content_type => "text/html", :body => body)
  end

  def user_warning(to, subject, body)
    mail(:from => AppConstants.tech_mail_from, :to => to, :subject => subject, :content_type => "text/html", :body => body)
  end

  def invalid_nationbuilder_sync(subject, message)
    mail(from: AppConstants.tech_mail_from, to: AppConstants.nationbuilder_admin_email, subject: subject, content_type: "text/html", body: message)
  end
end
