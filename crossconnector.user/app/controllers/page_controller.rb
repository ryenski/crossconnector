class PageController < ApplicationController
  
  layout "page"
  
  def show
    #begin
      @page = Page.find_by_permalink(params[:name])
    #rescue Exception => e
    #  raise ActiveRecord::RecordNotFound
    #end
  end
  
end
