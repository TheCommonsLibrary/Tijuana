class Theme < ActiveRecord::Base
  extend RemoveIdProtection

  def self.select_options
    self.select("id, display_name").all.inject([]) do |options, theme|
      options << [theme.display_name, theme.id]
      options
    end
  end
end
