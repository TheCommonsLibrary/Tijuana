module Admin::DashboardHelper
  def link_to_email(sent_email)
    email_subject = sent_email.subject
    email_link = check_email_connections(sent_email) {
      link_to(sent_email.subject, edit_admin_email_url(sent_email.email.id))
    }

    if email_link.match /DELETED/
      email_subject
    else
      email_link
    end
  end

  def link_to_campaign(sent_email)
    check_email_connections(sent_email) {
      link_to(sent_email.email.blast.push.campaign.name, admin_campaign_url(sent_email.email.blast.push.campaign.id))
    }
  end

  def link_to_push(sent_email)
    check_email_connections(sent_email) {
      link_to(sent_email.email.blast.push.name, url_for_push(sent_email))
    }
  end

  def campaign(sent_email)
    check_email_connections(sent_email) {
      sent_email.email.blast.push.campaign.name
    }
  end

  def push(sent_email)
    check_email_connections(sent_email) {
      sent_email.email.blast.push.name
    }
  end

  def url_for_push(sent_email)
    if sent_email.email && sent_email.email.blast && sent_email.email.blast.push
      admin_push_url(sent_email.email.blast.push.id)
    else
      nil
    end
  end

  private

  def check_email_connections(sent_email)
    if sent_email.email && sent_email.email.blast && sent_email.email.blast.push && sent_email.email.blast.push.campaign
      yield
    elsif !sent_email.email
      'EMAIL DELETED'
    elsif !(sent_email.email && sent_email.email.blast)
      'BLAST DELETED'
    elsif !(sent_email.email && sent_email.email.blast && sent_email.email.blast.push)
      'PUSH DELETED'
    else
      'CAMPAIGN DELETED'
    end
  end

end
