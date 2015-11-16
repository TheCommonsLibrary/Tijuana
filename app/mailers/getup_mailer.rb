class GetupMailer < ActionMailer::Base
  include InlineTokenReplacement
  helper :fragment
  default :from => "GetUp! <info@getup.org.au>"
  default :content_type => "text/html"

  def mail_using_generic_template(options, &block)
    if block_given?
      mail(:to => options[:to], :subject => options[:subject], &block)
    else
      mail(:to => options[:to], :subject => options[:subject]) do |format|
        format.html { render 'getup_mailer/generic_html_email' }
        format.text { render 'getup_mailer/generic_text_email' }
      end
    end
  end

  def mail(headers={}, &block)
    rewrite_from_header!(headers)
    super(headers, &block)
  end

private

  def rewrite_from_header!(headers)
    return if headers.nil? || headers[:from].blank?
    from_email = extract_email_from_field(headers[:from])
    regex = Regexp.union(AppConstants.invalid_email_from_domains)
    if from_email.match(regex)
      headers[:reply_to] = headers[:from]
      headers[:from] = invalidate_email(headers[:from])
    end
  end
  
  def extract_email_from_field(field)
    if field =~ /(.*)<(.*)>$/
      $2
    else
      field
    end
  end

  def invalidate_email(email_field)
    if email_field =~ /(.*)<(.*)>$/
      "#{$1} <#{$2}.invalid>"
    else
      email_field + '.invalid'
    end
  end
end
