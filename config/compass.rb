# Require any additional compass plugins here.
project_type = :rails
project_path = Rails.root if defined?(Rails.root)

# Set to true for easier debugging
line_comments         = true
preferred_syntax      = :sass

# CSS output style - :nested, :expanded, :compact, or :compressed
output_style          = :expanded

sass_dir = "app/assets/stylesheets"
images_dir = "app/assets/images"

module Sass::Script::Functions
  def _ify(string)
    assert_type string, :String
    Sass::Script::String.new(string.value.gsub(/[-]/, '_'))
  end
  declare :reverse, :args => [:string]
end
