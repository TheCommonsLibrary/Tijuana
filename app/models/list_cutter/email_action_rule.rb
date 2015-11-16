module ListCutter
  class EmailActionRule < Rule
    fields :email_id, :action
    validates :action, :presence => { :message => "Please specify the email status" }
    validates :email_id, :presence => { :message => "Please specify the email id" }

    def active?
      !email_id.blank?
    end

    def to_relation
      email_ids = email_id.split(',').map(&:to_i)
      emails = Email.find(email_ids, :include => {:blast => :push})
      grouped_emails = emails.group_by { |e| e.blast.push.id }
      relation = User
      grouped_emails.each { |push_id,emails|
        relation = relation.joins(push_fragment(push_id, emails))
      }
      if negate?
        relation.where(grouped_emails.map { |push_id,emails| "push_#{push_id}.user_id IS NULL"}.join(" AND "))
      else
        relation.where(grouped_emails.map { |push_id,emails| "push_#{push_id}.user_id = users.id"}.join(" OR "))
      end
    end

    private

    def push_fragment(push_id, emails)
      push_table = "push_#{push_id}"
      email_ids = emails.map(&:id)
      <<HERE
LEFT OUTER JOIN #{push_table}
  ON  users.id = #{push_table}.user_id
  AND #{push_table}.activity = '#{action}'
  AND #{push_table}.email_id IN (#{email_ids.join(',')})
HERE
    end
  end
end
