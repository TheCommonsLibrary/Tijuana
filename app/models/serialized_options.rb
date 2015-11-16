module SerializedOptions
  def self.included(mod)
    mod.class_eval do
      serialize :options
    end
    mod.send :extend, ClassMethods
    mod.send :include, InstanceMethods
  end

  module ClassMethods
    # expose serialized options as attributes
    def option_fields(*fields)
      fields = fields.map(&:to_sym)
      fields.each do |field|
        define_method "#{field}" do
          self.options = {} if self.options.blank?
          self.options[field]
        end
        define_method "#{field}=" do |value|
          self.options = {} if self.options.blank?
          self.options[field] = value
          self.updated_at = Time.now
        end
      end
    end
    
    def typed_option_field(field, field_type)
      if field_type == :boolean
        define_method "#{field}?" do
          self.options = {} if self.options.blank?
          self.options[field]
        end
      end
      define_method "#{field}" do
        self.options = {} if self.options.blank?
        self.options[field]
      end
      define_method "#{field}=" do |value|
        self.options = {} if self.options.blank?
        self.options[field] = type_cast value, field_type
        self.updated_at = Time.now
      end
    end
  end

  module InstanceMethods
    def type_cast(value, field_type)
      return nil if value.nil?

      klass = ActiveRecord::ConnectionAdapters::Column

      case field_type
      when :string, :text        then value
      when :integer              then ActiveRecord::Type::Integer.new.type_cast_from_user(value)
      when :float                then value.to_f
      when :decimal              then ActiveRecord::Type::Decimal.new.type_cast_from_user(value)
      when :datetime, :timestamp then ActiveRecord::Type::DateTime.new.type_cast_from_user(value)
      when :time                 then ActiveRecord::Type::Time.new.type_cast_from_user(value)
      when :date                 then ActiveRecord::Type::Date.new.type_cast_from_user(value)
      when :binary               then ActiveRecord::Type::Binary.new.type_cast_from_user(value)
      when :boolean              then ActiveRecord::Type::Boolean.new.type_cast_from_user(value)
      else value
      end
    end
    
    #def options
    #  @options ||= begin
    #    result = read_attribute(:options)
    #    p "unserializing: #{result.unserialize}"
    #    p "unserializing-1: #{result}"
    #    p "read_attribute: #{result.inspect}"
    #    if result.respond_to?(:unserialized_value) && result.unserialized_value.nil?
    #      result.value = {}
    #    end
    #    if result.nil?
    #      write_attribute(:options, result = {})
    #    end
    #    result
    #    p "RETURNING #{result.inspect}"
    #    result
    #  end
    #end
  end
end
