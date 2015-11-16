module CustomFieldsFromContentModule
  extend ActiveSupport::Concern

  included do
    store :dynamic_attributes
    validate :required_custom_form_fields_are_present, if: -> { self.has_custom_form_fields? }
    alias_method_chain :content_module=, :custom_form_fields
    after_find :ensure_custom_field_accessors_exist
  end

  def has_custom_form_fields?
    self.content_module.has_custom? :form_fields
  end

  def required_custom_form_fields_are_present
    for_each_custom_form_field_with(:required) do |required_form_field|
      unless required_form_field[:unique] && all_options_taken?(required_form_field)
        add_error_if_attribute_blank(required_form_field[:name])
      end
    end
    for_each_option_field_with_selected_value_with(:requires) do |custom_field, selected_option|
      unless all_options_taken? selected_option
        add_error_if_attribute_blank(selected_option[:requires])
      end
    end
  end

  def all_options_taken?(form_field)
    if form_field[:unique]
      options_taken = self.content_module.actions_on_page(self.page.id).map { |o| o.dynamic_attributes[form_field[:name]] }
      taken_hash = {}
      options_taken.each { |k| taken_hash[k] = true }

      count = form_field[:options][0][:value].blank? ? 1 : 0 # check if it contains prompt text
      form_field[:options].each do |o|
        count += 1 if o[:value].present? && taken_hash[o[:value]]
      end

      count == form_field[:options].size
    end
  end

  def add_error_if_attribute_blank(attribute)
    if self.send(attribute).blank?
      self.errors.add(attribute, "is required")
    end
  end

  def for_each_option_field_with_selected_value_with(custom_attribute)
    for_each_custom_form_field_with(:options) do |custom_field|
      selected_value = self.send(custom_field[:name])
      if selected_value.present?
        selected_option = find_option_for_value(custom_field, selected_value)
        if selected_option.nil?
          errors.add(custom_field[:name], 'is not one of the supplied options')
        else
          if selected_option[custom_attribute]
            yield(custom_field, selected_option)
          end
        end
      end
    end
  end

  def find_option_for_value(custom_fields, value)
    custom_fields[:options].detect { |field| field[:value].to_s == value }
  end

  def for_each_custom_form_field_with(key)
    self.content_module.custom(:form_fields).select { |v| v[key] }.each do |custom_field|
      yield(custom_field)
    end
  end

  def content_module_with_custom_form_fields= content_module
    self.content_module_without_custom_form_fields= content_module
    ensure_custom_field_accessors_exist
  end

  def ensure_custom_field_accessors_exist
    if content_module && content_module.has_custom?(:form_fields)
      content_module.custom(:form_fields).each do |custom_field|
        self.class.store_accessor(:dynamic_attributes, custom_field[:name]) unless self.respond_to?(custom_field[:name])
      end
    end
  end

end
