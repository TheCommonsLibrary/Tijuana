module ListCutter
  class CountryRule < Rule
    fields :country_iso
    validates :country_iso, :presence => { :message => "Please specify a country code" }

    def to_relation
      operator = negate? ? "!=" : "="
      User.where(["country_iso #{operator} ?", country_iso])
    end
    
    def active?
      !country_iso.blank? 
    end
  end
end
