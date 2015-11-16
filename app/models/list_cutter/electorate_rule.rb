module ListCutter
  class ElectorateRule < Rule
    fields :electorate_ids, :send_to_no_postcode
    validates :electorate_ids, :presence => { :message => "Please specify the electorates" }

    def to_relation
      operator = negate? ? "not in" : "in"
      if send_to_no_postcode?
        User.where("(postcode_id #{operator} (?) OR postcode_id IS NULL)", postcode_ids_from_electorates)
      else
        User.where("postcode_id #{operator} (?)", postcode_ids_from_electorates)
      end
    end
    
    def send_to_no_postcode?
      send_to_no_postcode == '1'
    end

    def active?
      !electorate_ids.blank?
    end
  private

    def postcode_ids_from_electorates
      postcodes = Electorate.where(id: electorate_ids).map { |electorate| electorate.postcodes }.flatten.uniq
      postcodes.collect { |p| p.id }
    end
  end

end
