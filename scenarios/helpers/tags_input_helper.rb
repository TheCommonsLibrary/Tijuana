module TagsInputHelper
  def fill_in_tags(locator, opts)
    wait_until { page.has_css? ".tagsinput" }
    field_id = find_field(locator, :visible => false)["id"]
    opts[:with].split(",").each do |tag|
      page.execute_script %{ $("##{field_id}").addTag("#{tag.strip}"); }
    end
    page.execute_script %{ $("##{field_id}").show(); }
  end
end
RSpec.configuration.include TagsInputHelper, :type => :feature 
