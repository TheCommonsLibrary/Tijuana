module SerializeUnknownAttributes
  extend ActiveSupport::Concern

  included do
    serialize :data, HashWithIndifferentAccess
  end

  def [](key)
    data[key] || super
  end

  module ClassMethods
    def serialized_create(hash)
      extras = hash.slice!(*new.attributes.keys)
      create!(HashWithIndifferentAccess.new(hash.merge(data: extras)))
    end
  end

end
