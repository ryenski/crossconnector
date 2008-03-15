class PageSweeper < ActionController::Caching::Sweeper
  
  observe Page
  
  def after_save(page)
    # expire_page
  end
  
  def after_update(page)
    
  end
  
end