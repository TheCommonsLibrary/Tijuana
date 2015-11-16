module ListCutter
  class EmailAddressesRule < Rule
    fields :email_addresses_string
    validates :email_addresses_string, :presence => { :message => "Please enter email addresses, one per line" }

    def to_relation
      operator = negate? ? "not in" : "in"
      User.where(["users.email #{operator} (?)", email_addresses])
    end
    
    def active?
      !email_addresses_string.blank? 
    end

private
    
    def email_addresses
      return [] if email_addresses_string.empty?
      email_addresses_string.split("\n").collect(&:strip)
    end

  end
end
