class Street < ActiveRecord::Base
  belongs_to :postcode

    scope :unallocated_for_content_module_id, ->(content_module_id) {
    street = self.arel_table
    street_user_module = StreetUserModule.arel_table
    where(
        StreetUserModule
          .where(
            street[:id].eq(street_user_module[:street_id])
            .and(street_user_module[:content_module_id].eq(content_module_id))
        ).exists.not
    )
  }

  scope :unallocated_for_content_module_id_and_suburb, ->(content_module_id, suburb_name) {
    where(suburb_name: suburb_name).unallocated_for_content_module_id(content_module_id).order(:name)
  }

  def self.suburbs 
    select(:suburb_name).uniq
  end

end
