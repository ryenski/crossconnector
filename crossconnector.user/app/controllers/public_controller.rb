class PublicController < ApplicationController
  # caches_page
  # session :off
  
  helper 'admin/event'
  helper 'admin/file'
  helper 'admin/teams'
  
  @@objects_per_page = 10
  
  layout :theme_layout
  
  def index
    redirect_to :action => "homebase"
  end
  
  def homebase
    @page_title = nil
    @recent_messages = @homebase.public_messages.find(:all, :limit => 3)
    @recent_projects = @homebase.public_projects.find(:all, :limit => 3)
    @recent_files = @homebase.public_files.find(:all, :limit => 3)
    # Log the visit 
    # To Do: See if this can be extended into ActiveRecord somehow. 
    # Maybe not because of the request things
    # Should be able to pass the request object as a parameter
    AccessLog.create(:public_homebase_id => Homebase.current_homebase.id, 
                     :request => request.env["REQUEST_URI"], 
                     :ip => request.env["REMOTE_ADDR"],
                     :referrer => request.env["HTTP_REFERER"],
                     :user_agent => request.env["HTTP_USER_AGENT"],
                     :language => request.env["HTTP_ACCEPT_LANGUAGE"],
                     :host => request.env["HTTP_HOST"])
  end
  
  def messages
    if params[:tag]
      m = @homebase.public_messages.find_tagged_with(:any => params[:tag], :separator => ",", :homebase => true, :conditions => "private != 1 and draft != 1")
      @messages_pages = Paginator.new self, m.size, @@objects_per_page, @params['page']
      @messages = @homebase.public_messages.find_tagged_with :any => params[:tag], :separator => ",", :homebase => true, :conditions => "private != 1 and draft != 1", :limit => @messages_pages.items_per_page, :offset => @messages_pages.current.offset
    else
      @messages_pages = Paginator.new self, @homebase.public_messages.count, @@objects_per_page, @params['page']
      @messages = @homebase.public_messages.find(:all, :limit => @messages_pages.items_per_page, :offset => @messages_pages.current.offset)
    end
    @related_tags = Message.find_tags_for_homebase# unless @messages.empty?
    @page_title = "Messages"
  end

  def projects
    if params[:tag]
      @projects_pages = Paginator.new self, @homebase.public_projects.find_tagged_with(:any => params[:tag], :separator => ",", :homebase => true, :conditions => "private != 1").size, @@objects_per_page, @params['page']
      @projects = @homebase.public_projects.find_tagged_with(:any => params[:tag], :separator => ",", :homebase => true, :conditions => "private != 1", :limit => @projects_pages.items_per_page, :offset => @projects_pages.current.offset)
      
    else
      @projects_pages = Paginator.new self, @homebase.public_projects.count, @@objects_per_page, @params['page']
      @projects = @homebase.public_projects.find(:all, :limit => @projects_pages.items_per_page, :offset => @projects_pages.current.offset)
    end
    @related_tags = Project.find_tags_for_homebase unless @projects.empty?
    @page_title = "Projects"
  end

  def files
    if params[:tag]
      @files_pages = Paginator.new self, @homebase.public_files.find_tagged_with(:any => params[:tag], :separator => ",", :homebase => true, :conditions => "private != 1").size, @@objects_per_page, @params['page']
      @files = @homebase.public_files.find_tagged_with(:any => params[:tag], :separator => ",", :homebase => true, :conditions => "private != 1", :limit => @files_pages.items_per_page, :offset => @files_pages.current.offset)
    else
      @files = @homebase.public_files
      
      @files_pages = Paginator.new self, @homebase.public_files.count, @@objects_per_page, @params['page']
      @files = @homebase.public_files.find(:all, :limit => @files_pages.items_per_page, :offset => @files_pages.current.offset)
      
    end
    @related_tags = Resource.find_tags_for_homebase unless @files.empty?
    @page_title = "Files"
  end
  
  def message
    begin      
      @message = @homebase.messages.find_by_permalink(params[:permalink])
      if @message.private? and (session["message_#{@message.id}"].nil? or session["message_#{@message.id}"] != @message.id)
        store_location
        render :partial => "login", :layout => "public_login", :locals => {:object => @message} and return
      end
      @related_messages = @message.project.messages if @message.project
      AccessLog.create(:message_id => @message.id,:request => request.env["REQUEST_URI"],:ip => request.env["REMOTE_ADDR"],:referrer => request.env["HTTP_REFERER"],:user_agent => request.env["HTTP_USER_AGENT"],:language => request.env["HTTP_ACCEPT_LANGUAGE"],:host => request.env["HTTP_HOST"])
      @page_title = @message.subject
    rescue Exception => e
      flash[:notice], flash[:class] = "That message was not found.", "bad"
      redirect_to :action => "messages"
    end
  end

  def project
    begin
      @project = @homebase.projects.find_by_permalink(params[:permalink])
      if @project.private? and (session["project_#{@project.id}"].nil? or session["project_#{@project.id}"] != @project.id)
        store_location
        render :partial => "login", :layout => "public_login", :locals => {:object => @project} and return
      end
      AccessLog.create(:project_id => @project.id,:request => request.env["REQUEST_URI"],:ip => request.env["REMOTE_ADDR"],:referrer => request.env["HTTP_REFERER"],:user_agent => request.env["HTTP_USER_AGENT"],:language => request.env["HTTP_ACCEPT_LANGUAGE"],:host => request.env["HTTP_HOST"])
      @page_title = @project.name
    rescue Exception => e
      flash[:notice], flash[:class] = "Sorry, we were not able to access that project.", "bad"
      redirect_to :action => "projects"
    end
  end
  
  def file
    begin
      @file = @homebase.public_files.find_by_permalink(params[:permalink])
      AccessLog.create(:resource_id => @file.id, :request => request.env["REQUEST_URI"], :ip => request.env["REMOTE_ADDR"],:referrer => request.env["HTTP_REFERER"],:user_agent => request.env["HTTP_USER_AGENT"],:language => request.env["HTTP_ACCEPT_LANGUAGE"],:host => request.env["HTTP_HOST"])
      
      if @file.class == Image
        case params[:size]
        when "screen"
          redirect_to File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}","images", @file[:id].to_s, "screen", @file[:file])
        when "thumbnail"
          redirect_to File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}", "images", @file[:id].to_s, "thumb", @file[:file])
        else
          redirect_to File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}", "images", @file[:id].to_s, @file[:file])
        end
      else
        redirect_to File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}", "files", @file[:id].to_s, @file[:file])
      end
      
    rescue Exception => e
      flash[:notice], flash[:class] = "That file was not found.", "bad"
      redirect_to :action => "files"
    end
  end
  
  #
  # Login for private items
  # 
  def login
    if request.post?
      
      if object = Module.const_get(params[:object].capitalize).authenticate(params[:permalink], params[:password])
        session["#{object.class.to_s.downcase}_#{object.id}"] = object.id
      else
        flash[:notice], flash[:class] = "Sorry, we didn't recognize that password.", "bad"
      end
      redirect_to :action => params[:object], :permalink => params[:permalink] and return
    else
      render :layout => "public_login" and return
    end
  end
  
  
  def about
    @page_title = "About Us"
  end
  
  def render_404
    render :file => "public/404.html", :status => 404
  end
end
