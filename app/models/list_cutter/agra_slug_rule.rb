module ListCutter
  class AgraSlugRule < Rule
    fields :slug
    validates :slug, :presence => { :message => "Please specify a existing slug" }

    def to_relation
      slugs = slug.split(",").map(&:strip)
      condition = AgraAction.arel_table[:slug].in(slugs)

      if negate?
        User.joins("LEFT OUTER JOIN agra_actions ON agra_actions.user_id = users.id AND #{condition.to_sql}")
            .where("agra_actions.id IS NULL")
      else
        User.joins(:agra_actions).where("agra_actions.slug IN (?)", slugs)
      end
    end

    def active?
      !slug.blank?
    end

    def has_agra_rule?
      true
    end
  end
end
