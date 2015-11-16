class AddExternalActionsJob
  def initialize(list, page)
    @list = list
    @page = page
  end
  
  def perform
    user_ids = @list.filter_by_rules_and_relation(exclude_duplicates_relation)
    user_ids.each { |id| UserActivityEvent.external_action!(id, @page) }
    @list.destroy
  end


private

  def exclude_duplicates_relation
    join = <<JOIN
    LEFT OUTER JOIN user_activity_events uae_dup
    ON uae_dup.user_id = users.id
    AND uae_dup.page_id = #{@page.id}
JOIN
    User.joins(join).where("uae_dup.id IS NULL")
  end

end
