module PatchSingleTableInheritanceForPrivilegedUser
  extend ActiveSupport::Concern

  included do
    self.inheritance_column = :dummy_sti_trigger
  end

  module ClassMethods
    def instantiate(attributes, column_types = {})
      klass = find_sti_class(attributes)
      attributes = klass.attributes_builder.build_from_database(attributes, column_types)
      klass.allocate.init_with('attributes' => attributes, 'new_record' => false)
    end

    def find_sti_class(record)
      return PrivilegedUser if record["is_admin"] == 1 || record["is_volunteer"] == 1
      return self
    end
  end

end
