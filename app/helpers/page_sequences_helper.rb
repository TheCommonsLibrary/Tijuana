module PageSequencesHelper
  def default_theme_chooser
    @page_sequence.theme ? @page_sequence.theme.id : Setting.try(:[], 'default_theme')
  end
end
