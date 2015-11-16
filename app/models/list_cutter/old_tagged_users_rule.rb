module ListCutter
  class OldTaggedUsersRule < Rule
    REGEX_TEMPLATE = "(^|,){TAG}(,|$)"
    fields :old_tags
    validates :old_tags, :presence => { :message => "Please provide one or more tags" }

    def to_relation
      operator = negate? ? "not regexp" : "regexp"
      relation = User
      old_tags.split(",").each do |tag|
        relation = relation.where(["old_tags #{operator} ?", REGEX_TEMPLATE.sub("{TAG}", tag.strip)])
      end
      relation
    end
    
    def active?
      !old_tags.blank?
    end
  end
end
