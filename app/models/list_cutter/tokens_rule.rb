module ListCutter
  class TokensRule < Rule
    fields :tokens_string
    validates :tokens_string, :presence => { :message => "Please enter tokens, one per line" }

    def to_relation
      operator = negate? ? "not in" : "in"
      User.where(["users.id #{operator} (?)", ids])
    end
    
    def active?
      !tokens_string.blank? 
    end

private
    
    def ids
      return [] if tokens_string.empty?
      tokens = tokens_string.split("\n").collect(&:strip)
      tokens.collect {|t| EmailTrackingToken.decode(t)[:userid]}.reject{|id| !id}
    end

  end
end
