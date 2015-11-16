module ListCutter
  class EmailDomainRule < Rule
    fields :domain
    validates :domain, :presence => { :message => "Please specify the email server" }

    def initialize(params={})
      super
      @params[:domain] = cleanup_domain
    end

    def cleanup_domain
      if domain && domain.index('@')
        domain.split('@')[1]
      else
        domain
      end
    end
    private :cleanup_domain

    def to_relation
      operator = negate? ? "not like" : "like"
      User.where(["email #{operator} ?", "%@#{domain}"])
    end
    
    def active?
      !domain.blank?
    end
  end
end