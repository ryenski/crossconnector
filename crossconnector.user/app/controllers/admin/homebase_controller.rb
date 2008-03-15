class Admin::HomebaseController < ApplicationController
  
  #helper :sparklines
  
  before_filter :login_required
  #layout "application2"
  
  def index
    @page_title = "Homebase"

    @received_messages = Message.find_received_messages
    @received_projects = Project.find_received_projects
    @received_files = Resource.find_received_files
    
    @recent_projects = @homebase.projects.find(:all, :limit => 3)
    @recent_messages = @homebase.messages.find(:all, :limit => 3)
    @recent_files = @homebase.files.find(:all, :limit => 3)
    
    @alert = Alert.find_current_alert
  end
end
