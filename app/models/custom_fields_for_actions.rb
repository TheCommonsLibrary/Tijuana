module CustomFieldsForActions
  extend ActiveSupport::Concern

  included do
    option_fields :custom_fields
    validate :parse_and_validate_custom_fields_yaml
  end

  def parse_and_validate_custom_fields_yaml
    if @custom_fields_as_yaml
      begin
        doc = YAML.load(@custom_fields_as_yaml)
        errors.add(:custom_fields, 'Invalid YAML document') if doc == false
        doc
      rescue Exception => ex
        message = ex.message.gsub('(<unknown>):','')
        errors.add(:custom_fields, message)
        nil
      end
    end
  end

  def custom_fields_as_yaml=(arg)
    @custom_fields_as_yaml = arg.without_smartquotes
    @custom_fields_as_yaml = "---\n" if @custom_fields_as_yaml.strip.empty? 
    self.custom_fields = parse_and_validate_custom_fields_yaml
  end

  def custom_fields_as_yaml
    @custom_fields_as_yaml || self.custom_fields.to_yaml
  end

  def custom(field_type)
    custom_fields.try(:[], field_type) || {}
  end

  def has_custom?(field_type)
    custom(field_type).present?
  end
end
