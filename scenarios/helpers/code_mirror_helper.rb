module CodeMirrorHelper
  def fill_in_code_mirror(text)
    id = "#{current_css_path} #" + page.evaluate_script("$('#{current_css_path}').find('textarea')[0].id;")
    page.execute_script("$('#{id}').data('codeMirror').setValue('#{text}');")
  end
end
RSpec.configuration.include CodeMirrorHelper, :type => :feature 
