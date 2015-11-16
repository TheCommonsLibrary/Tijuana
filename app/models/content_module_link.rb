class ContentModuleLink < ActiveRecord::Base
  belongs_to :page
  belongs_to :content_module
  acts_as_list :scope => 'page_id=#{page_id} and layout_container=\'#{layout_container}\''
  
  def layout_container
    str = read_attribute(:layout_container)
    str ? str.to_sym : nil
  end
end