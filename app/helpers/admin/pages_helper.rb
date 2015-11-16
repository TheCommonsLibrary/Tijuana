module Admin::PagesHelper
  def edit_content_module_partial(content_module)
    "admin/pages/content_modules/#{content_module.class.name.underscore}"
  end
  
  def add_content_module_link(module_type, container, text)
    link_to(text, add_content_module_admin_page_path(@page, :type => module_type, :container => container), :remote => true, :class => "add-module-link #{module_type.name.underscore}")
  end

  def external_module_link(module_type, text)
    plural = module_type.name.pluralize.underscore
    link_to(text, "/admin/#{plural}", :class => "add-module-link #{plural}_module", :target => "_blank")
  end

  def note_module_cannot_be_used_if_aside_has_content
    "<strong>Note:</strong> This module cannot be used if aside has content".html_safe
  end

  def options_for_member_value(include_money=false)
    options = [ ['Voice', 'voice'], ['Time', 'time'] ]
    options << ['Money', 'money'] if include_money
    options
  end

  def options_for_member_value_range(ranges, use_currency)
    options = []
    position = 0
    options << ["-- Please select", -1]
    currency_symbol = use_currency ? '$' : ''
    ranges.each { |r|
      if r == ranges.first
        options << ["#{currency_symbol}#{r[0]}", position]
      elsif r == ranges.last
        options << ["#{currency_symbol}#{r[0]}+", position]
      else
        options << ["#{currency_symbol}#{r[0]} - #{currency_symbol}#{r[1]}", position]
      end
      position += 1
    }

    options
  end
end
