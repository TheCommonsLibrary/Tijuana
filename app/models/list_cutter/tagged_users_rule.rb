module ListCutter
  class TaggedUsersRule < Rule
    REGEX_TEMPLATE = "(^|,){TAG}(,|$)"
    fields :tags
    validates :tags, :presence => { :message => "Please provide one or more tags" }
    validate :tags_must_exist

    def to_relation
      if negate?
        User.joins("LEFT OUTER JOIN taggings on users.id = taggings.taggable_id AND taggings.taggable_type = 'User' AND #{tag_id_condition}").where('taggings.id IS NULL')
      else 
        User.joins("INNER JOIN taggings ON users.id = taggings.taggable_id AND taggings.taggable_type = 'User'").where('taggings.tag_id in (?)', get_tag_ids)
      end
    end

    def active?
      !tags.blank?
    end

    def tags_must_exist
      errors.add(:tags, "No tags found.") if get_tag_ids.size == 0
    end

  private

    def get_tag_ids
      tag_list = tags.split(',').map(&:strip)
      tags_table = Arel::Table.new(:tags)
      query = tags_table.where(tags_table[:name].in(tag_list)).project(tags_table[:id])
      ActiveRecord::Base.connection.select_values(query)
    end

    def tag_id_condition
      taggings_table = Arel::Table.new(:taggings)
      taggings_table[:tag_id].in(get_tag_ids).to_sql
    end
  end
end
