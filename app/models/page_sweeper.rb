class PageSweeper < ActionController::Caching::Sweeper
  observe Page

  def after_update(page)
    expire_cache_for(page)
  end

  private
  def expire_cache_for(page)
    #TODO check this works in showcase/production
    ActionController::Base.new.expire_fragment(page.cache_key)
  end
end
