module ListCutter
  class CustomSqlRule < Rule
    fields :custom_sql
    validates :custom_sql, :presence => { :message => "Please specify some custom SQL" }
    validate :query_format

    def to_relation
      if negate?
        User.joins("LEFT OUTER JOIN (\n#{custom_sql}\n) custom_user_query ON custom_user_query.id = users.id")
        .where("custom_user_query.id IS NULL")
      else
        User.joins("INNER JOIN (\n#{custom_sql}\n) custom_user_query ON custom_user_query.id = users.id ")
      end
    end
    
    def active?
      !custom_sql.blank? 
    end

    def is_custom?
      true
    end

    def has_agra_rule?
      custom_sql.match(/agra_actions/)
    end
    
    private

    def query_format
      if custom_sql
        self.errors.add :custom_sql, 'Should start with a SELECT statement' unless custom_sql.strip.match /^select/i
        self.errors.add :custom_sql, 'Should not contain the character ";"' if custom_sql.match /;/
      end
    end
  end
end