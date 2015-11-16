class AddHtmlLineBreaksDisabled < ActiveRecord::Migration
  def change
    add_column :emails, :body_is_html_document, :boolean, default: false
  end
end
