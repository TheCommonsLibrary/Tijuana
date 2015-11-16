module ContentModuleHelper

  def render_custom_form_fields(form, form_fields, content_module)
    output = ""
    form_fields.map do |cf|
      case cf[:type]
        when "check_box"
          output << '<div class="custom-check-box">'
          output << form.label(cf[:name].to_sym, cf[:label], {class: 'checkbox'}) do |f|
            form.check_box(cf[:name].to_sym, {checked: cf[:value], class: 'full'}) + html_escape(cf[:label])
          end
          output << '</div>'
        when "text_field"
          output << '<div class="custom-text-field">'
          output << form.label(cf[:name].to_sym, cf[:label]) if cf[:label]
          output << form.text_field(cf[:name].to_sym, :placeholder => cf[:placeholder])
          output << field_errors(form.object, cf[:name].to_sym)
          output << '</div>'
          output << '<div class="clearfix"></div>'
        when "text_area"
          output << '<div class="custom-text-area">'
          output << form.label(cf[:name].to_sym, cf[:label]) if cf[:label]
          output << form.text_area(cf[:name].to_sym, :placeholder => cf[:placeholder])
          output << field_errors(form.object, cf[:name].to_sym)
          output << '</div>'
          output << '<div class="clearfix"></div>'
        when "select"
          if cf[:unique]
            output << add_unique_options(cf, form, content_module)
          else
            output << form.label(cf[:name].to_sym, cf[:label])
            output << form.select(cf[:name].to_sym, cf[:options].map { |option| [option[:text], option[:value]] })
          end

          output << field_errors(form.object, cf[:name].to_sym)
      end
    end

    output.html_safe
  end

  def add_unique_options(cf, form, content_module)
    options_taken = content_module.actions_on_page(@page.id).map {|o| o.dynamic_attributes[cf[:name]]}
    contains_prompt_text = cf[:options][0][:value].nil?

    taken_hash = {}
    output = ''
    options_taken.each {|k| taken_hash[k] = true }

    options_available = cf[:options].select { |o| o[:value].nil? || !taken_hash[o[:value].to_s] }

    if (contains_prompt_text && options_available.size == 1) || options_available.size == 0
      output << "<div class='clearfix'></div><div class='empty-field-text'>#{cf[:no_options_text]}</div>"
    else
      output << form.label(cf[:name].to_sym, cf[:label])
      output << form.select(cf[:name].to_sym, options_available.map { |option| [option[:text], option[:value]] })
    end

    output
  end
end
