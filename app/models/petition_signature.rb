class PetitionSignature < ActiveRecord::Base
  include ActsAsUserResponse
  include CustomFieldsFromContentModule

  attr_accessor :source

  scope :recent_names, ->(id) {
    select('users.first_name, users.last_name')
      .joins('JOIN users ON petition_signatures.user_id = users.id')
      .where('petition_signatures.page_id = ?', id)
      .where('LENGTH(users.first_name) >= 3')
      .where('LENGTH(users.last_name) >= 3')
      .order('petition_signatures.created_at DESC')
      .limit(200)
    }
end
