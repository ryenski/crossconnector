class FeedController < ApplicationController
  #caches_page :feed
  session :off
  
  def rss

    @items, @projects, @messages, @files = Array.new
    @feed_title = ("#{@homebase.name} - #{@params[:type] || "All items"}")
    
    case params[:type]
    when 'message'
      @messages = @homebase.public_messages.find(:all)
      @link = url_for :controller => "public", :action => "messages"
    when 'project'
      @projects = @homebase.public_projects.find(:all)
      @link = url_for :controller => "public", :action => "projects"
    when 'file'
      @files = @homebase.public_files.find(:all)
      @link = url_for :controller => "public", :action => "files"
    else
      @messages = @homebase.public_messages.find(:all, :limit => 10)
      @projects = @homebase.public_projects.find(:all, :limit => 10)
      @files    = @homebase.public_files.find(:all, :limit => 10)
      @link = url_for :controller => "public", :action => "index"
    end
    render_without_layout
  end
  
end
