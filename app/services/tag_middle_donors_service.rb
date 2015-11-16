class TagMiddleDonorsService
  def self.tag!
    middle_donor_tag = ActsAsTaggableOn::Tag.find_or_create_by_name('middledonor')
    major_donor_tag = ActsAsTaggableOn::Tag.find_or_create_by_name('majordonor')
    apply_tag(major_donor_tag, 5000, keep_existing: true)
    apply_tag(middle_donor_tag, 250, exclude_tag: major_donor_tag)
  end

  private

  def self.apply_tag(tag, amount, exclude_tag: nil, keep_existing: false)
    temp_tag = ActsAsTaggableOn::Tag.find_or_create_by_name("temp:#{tag.name}")
    sql = "SELECT DISTINCT(users.id) FROM `users` "
    sql += "INNER JOIN `donations` ON `donations`.`user_id` = `users`.`id` "
    sql += "INNER JOIN `transactions` on transactions.donation_id = donations.id and not refunded and successful and transactions.amount_in_cents  >= #{amount*100} "
    if exclude_tag
      sql += "LEFT OUTER JOIN taggings on users.id = taggings.taggable_id AND taggings.taggable_type = 'User' AND tag_id = #{exclude_tag.id} "
    end
    sql += "WHERE (`users`.deleted_at IS NULL) "
    sql += "AND (taggings.id IS NULL)" if exclude_tag
    User.find_by_sql(sql).each do |user|
      user = User.find(user.id)
      user.tag_list.add(temp_tag)
      user.save!
    end
    unless keep_existing
      User.tagged_with(tag.name).tagged_with(temp_tag.name, exclude: true).remove_tags([tag.name])
    end
    User.tagged_with(temp_tag).add_tags([tag.name])
    User.tagged_with(temp_tag).remove_tags([temp_tag.name])
  end
end
