class AddTagsJob
  def initialize(list, tags)
    @list = list
    @tags = tags
  end
  
  def perform
    user_ids = nil
    user_ids = @list.filter_by_rules

    AddTagsJob.add_tags user_ids, @tags
    
    @list.destroy
  end
  
  def self.add_tags(user_ids, tags)
    tags = tidy_tags(tags)
    
    User.where(:id => user_ids).add_tags tags

    NationBuilder::SyncTagsFromTjToNbService.new.sync! tags
  end
  
  private
  
  def self.tidy_tags(tags)
    tags.split(",").map(&:strip)
  end
end
