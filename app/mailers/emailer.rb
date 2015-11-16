class Emailer < GetupMailer
  include SendgridSupport
  include SendGrid
  include SendgridTokenReplacement

  def sender
    "GetUp! Donations <donations@getup.org.au>"
  end

  def self.split_addresses(addresses)
    return [] unless addresses.present?
    addresses.gsub(",", " ").gsub(";", " ").split
  end

  def thankyou_email(target, subject, body)
    @body_text = body
    mail(:to => target,
         :subject => subject)
  end

  def deliver_to_targets?
    Rails.env.production? || Rails.env.test?
  end

  def dev_email_address(targets)
    addresses = Emailer.split_addresses(targets)
    dev_email = addresses.map{|address| address.gsub('@','_') }.join("&")
    "tech-dev+#{dev_email}@getup.org.au"
  end

  def target_email(targets, from, cc, subject, body, tracking_token=nil)
    @body_text = body
    @tracking_token = tracking_token
    to =  deliver_to_targets? ? Emailer.split_addresses(targets) : dev_email_address(targets)
    mail(:to => to,
         :from => from,
         :cc => cc,
         :subject => subject)
  end

  def recurring_receipt_email(donation, trans)
    @donation = donation
    @transactions = trans
    @user = @donation.user
    @greeting = @user.greeting || "Friend"
    @transaction_ids = @transactions.map(&:txn_ref)
    @subject = "Welcome to the GetUp Crew, #{@greeting}"
    email = mail(to: @user.email, from: sender, subject: @subject)
    # replace line breaks here to avoid spacing issues when making edits
    # line breaks need to be removed for gmail
    email.body.raw_source.replace(email.body.raw_source.gsub("\n", ""))
  end

  def one_off_receipt_email(donation, trans)
    @donation = donation
    @transactions = trans
    @user = @donation.user
    @greeting = @user.greeting || "Friend"
    @frequency = "one off"
    @transaction_ids = @transactions.map(&:txn_ref)
    @subject = "Thanks for your donation #{@greeting}"
    mail(to: @user.email, from: sender, subject: @subject)
  end

  def make_recurring_receipt_email(donation)
    @donation = donation
    @user = @donation.user
    @greeting = @user.greeting || "Friend"
    @start_date = (donation.created_at + 1.month).to_date.to_s(:rfc822)

    mail(:to => @user.email,
         :from => sender,
         :subject => "Monthly Donation from GetUp (commences: #{@start_date}, ref: #{donation.id})")
  end

  def offline_donation_receipt_email(donation, trans)
    @donation = donation
    @donation.payment_method = donation.payment_method
    @transactions = trans
    @user = @donation.user
    @greeting = @user.greeting || "Friend"
    @frequency = @donation.frequency == "one_off" ? "one off" : " #{@donation.frequency}"
    @member_count = BigDecimal(MemberCountCalculator.current).floor(-3).to_i
    @transaction_ids = []
    @transactions.each do |txn|
      @transaction_ids.push txn.id
    end

    mail(:to => @user.email,
         :from => sender,
         :subject => "Approved #{@frequency.titlecase} Transaction from GetUp (ref: #{@transaction_ids.join(', ')})")
  end

  def refund_receipt_email(transaction)
    @transaction = transaction
    @donation = @transaction.donation
    @user = @donation.user

    @greeting = @user.greeting || "Friend"

    mail(:to => @user.email,
         :from => sender,
         :subject => "Refunded Transaction from GetUp (ref: #{@transaction.txn_ref})")
  end

  def cancelled_recurring_donation_email(donation)
    @donation = donation
    @user = @donation.user
    @frequency = @donation.frequency

    @greeting = @user.greeting || "Friend"

    mail(:to => @user.email,
         :from => sender,
         :subject => "Cancelled GetUp Crew Donation")
  end

  def blast(email_to_send, options)
    options[:recipients] = reject_unsafe_email_addresses(options[:recipients])
    if options[:recipients].empty?
      self.message.perform_deliveries = false
      return
    end

    @body_text = {:html => email_to_send.html_body, :text => email_to_send.plain_text_body}
    headers['X-SMTPAPI'] = prepare_sendgrid_headers(email_to_send, options)
    @footer = email_to_send.footer

    mail_message = mail(:to => 'does-not-matter@getup.org.au',
         :from => "#{email_to_send.from_name} <#{email_to_send.from_address}>",
         :reply_to => email_to_send.reply_to_address,
         :subject => get_subject(email_to_send, options)) do |format|
      format.text(content_transfer_encoding: 'quoted-printable'){
        @disable_text_footer = email_to_send.body_is_html_document?
        render
      }
      format.html(content_transfer_encoding: 'quoted-printable'){
        if email_to_send.body_is_html_document?
          render inline: safe_html_body_with_tracking_image
        else
          render
        end
      }
    end
    mail_message
  end

  def prepare_sendgrid_headers(email_to_send, options)
    email_headers = {
      'to' => options[:recipients],
      'category' => "P#{email_to_send.blast.push.id}_B#{email_to_send.blast.id}_E#{email_to_send.id}",
      'sub' => get_substitutions_list(email_to_send, options),
      'filters' => {
        'ganalytics' => {
          'settings' => {
            'enable' => '1',
            'utm_source' => 'blast',
            'utm_medium' => 'email',
            'utm_campaign' => email_to_send.subject.gsub(/[^\w]/, '_'),
            'utm_content' => email_to_send.id.to_s
          }
        }
      }
    }
    raise_error_if_sizes_dont_match(options[:recipients].size, email_headers['sub'][email_headers['sub'].keys.first].size)
    to_json_for_sendgrid(email_headers)
  end

  private :prepare_sendgrid_headers

  def raise_error_if_sizes_dont_match(no_recipients, no_tokens)
    if no_recipients != no_tokens
      msg = "Error sending blast. The number of recipients doesn't match the number of replacement tokens. #{no_recipients} != #{no_tokens}"
      Rails.logger.error msg
      raise RuntimeError.new msg
    end
  end

  private :raise_error_if_sizes_dont_match


  def get_subject(email_to_send, options)
    subject = email_to_send.subject
    subject = "[SHOWCASE]#{subject}" if Rails.env.showcase?
    subject = "[TEST]#{subject}" if options[:test]
    subject
  end
  private :get_subject

  protected

  def safe_html_body_with_tracking_image
    html = @body_text[:html]
    html.gsub!(/<\/body>/, "<img src=\"http://#{AppConstants.host}/beacon.gif?t={TRACKING_HASH|NOT_AVAILABLE}\"></body>")
    html.html_safe
  end
end
