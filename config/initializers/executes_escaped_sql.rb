module ExecutesEscapedSql
  extend ActiveSupport::Concern

  def execute_escaped(*args)
    self.class.execute_escaped *args
  end
  
  module ClassMethods
    def execute_escaped(*args)
      escaped_sql = ActiveRecord::Base.send :sanitize_sql_array, args
      ActiveRecord::Base.connection.execute escaped_sql
    end
  end
end

ActiveRecord::Base.send :include, ExecutesEscapedSql