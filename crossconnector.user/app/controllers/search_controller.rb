class SearchController < ApplicationController

  def search
    
    if request.post? or request.xhr?
      @query = params[:query].to_s

      @results = Message.search(@query, :conditions => "private != 1 AND draft != 1")
      @results += Project.search(@query, :conditions => "private != 1")
      
      
      render :partial => "results", :layout => false, :locals => {:results => @results, :query => @query}
    end
    
  end
end
