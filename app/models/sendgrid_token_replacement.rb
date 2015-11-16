module SendgridTokenReplacement
  TOKENS_REGEX = /\{([^\{]*\|[^\{]*)\}/m #matches tokens of the form {TOKEN_NAME|DEFAULT_VALUE}
  NEAREST_EVENT_SEARCH_RADIUS_KM = 50

  private 

  def get_substitutions_list(email, options)
    recipients_for_test = options[:test] ? options[:recipients] : nil

    # we group by email in the following query to safe guard against duplicate email addresses, a legacy from v2
    users = User.includes(:postcode).select("users.id, users.first_name, users.last_name, users.email, postcodes.number")
      .where("email in (?)", options[:recipients]).order("users.email").group("users.email").references(:postcode)
    options[:recipients].empty? ? {} : generate_replacement_tokens(email, users, recipients_for_test)
  end
  
  def generate_replacement_tokens(email, users, recipients_for_test = nil)
    sub = {}
    text_to_scan = "#{email.html_body} #{email.subject}"
    text_to_scan.scan(TOKENS_REGEX).uniq.each do |token_pair|
      token_name, default_value = token_pair[0].split("|")
      case token_name
        when "NAME" then
          set_tokens(sub, default_value, token_name, users, recipients_for_test) do |u|
            u.first_name.blank? ? default_value : u.first_name
          end
        when "POSTCODE" then
          set_tokens(sub, default_value, token_name, users, recipients_for_test) do |u|
            u.postcode.blank? ? default_value : u.postcode.number
          end
        when "CHIP_IN" then
          set_tokens(sub, default_value, token_name, users, recipients_for_test) do |u|
            u.donations.exists? ? default_value : "#{default_value} $12"
          end
        when "CLOSEST_EVENT_SUBURB" then
          set_tokens(sub, default_value, token_name, users, recipients_for_test) do |u|
            event = find_closest_event(email, u)
            event.nil? ? default_value : event.suburb
          end
        when "CLOSEST_EVENT" then
          set_tokens(sub, default_value, token_name, users, recipients_for_test) do |u|
            default_value= '<b><a href="https://www.getup.org.au/climate">RSVP to your nearest event now.</a></b>' # TEMP HACK TO WORK AROUND TEXT VERSIONS OF EMAILS
            render :partial => "getup_mailer/closest_event", :locals => { :user => u, :email => email, :recipients_for_test => recipients_for_test, :event => find_closest_event(email, u), :default_value => default_value }
          end
        when "CUSTOM_FRAGMENT" then
          set_tokens(sub, default_value, token_name, users, recipients_for_test) do |u|
            render :partial => "getup_mailer/custom_fragments/#{default_value}", :locals => { user: u, email: email, recipients_for_test: recipients_for_test, default_value: default_value } # partial needs to do its own error handling. Blast will stop if partial throws an error
          end
        when "SECURE_TOKEN" then
          set_tokens(sub, "NOT_AVAILABLE", "SECURE_TOKEN", recipients_for_test ? [] : users, recipients_for_test) do |u|
            SecureLinkToken.token(EmailTrackingToken.encode(u.id, email.id))
          end
        when /^MERGE/ then
          set_tokens(sub, default_value, token_name, users, recipients_for_test) do |u|
            merge_eval = MergeToken.get_eval(token_name)
            raise InvalidMergeToken.new("#{merge_eval} is not whitelisted") unless MergeToken.valid_eval?(merge_eval)
            value = (u.instance_eval(merge_eval) || default_value) rescue default_value

            next value unless value =~ /^http/
            token = EmailTrackingToken.encode(u.id, email.id)
            value.index('?') ? "#{value}&t=#{token}" : "#{value}?t=#{token}"
          end
      end
    end

    set_tokens(sub, "NOT_AVAILABLE", "TRACKING_HASH", recipients_for_test ? [] : users, recipients_for_test) do |u|
      EmailTrackingToken.encode(u.id, email.id)
    end

    set_tokens(sub, "NOT_AVAILABLE", "EMAIL", recipients_for_test ? [] : users, recipients_for_test) do |u|
      u.email
    end

    sub
  end

  def find_closest_event(email, user)
    postcode = user.postcode
    get_together_id = email.get_together_id

    return nil unless postcode

    EventPostcodeCache.fetch(get_together_id, postcode.number) do
      GetTogether.find(get_together_id).get_sorted_local_events(postcode, NEAREST_EVENT_SEARCH_RADIUS_KM, 1, :host).first
    end
  end

  def set_tokens(sub, default_value, token_name, users, recipients_for_test, &block)
    result = nil
    if recipients_for_test # sending test 
      result = [default_value] * recipients_for_test.length
      users.each do |u|
        index = recipients_for_test.index {|item| item.casecmp(u.email) == 0}
        result[index] = block.call(u)
      end
    else
      result = users.blank? ? [default_value] : users.map { |u| block.call(u) }
    end

    sub["{#{token_name}|#{default_value}}"] = result
  end  
end
