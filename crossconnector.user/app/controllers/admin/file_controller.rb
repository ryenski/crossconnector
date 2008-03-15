class Admin::FileController < ApplicationController
  
  helper :sparklines
  
  before_filter :login_required, :except => [:download]
  before_filter :page_title
  
  @@objects_per_page = App::CONFIG[:objects_per_page]
  
  def index
    @file_pages = Paginator.new self, @homebase.files.count, @@objects_per_page, @params['page']
    @files = @homebase.files.find(:all, :limit => @file_pages.items_per_page, :offset => @file_pages.current.offset)
  end
  
  def show
    redirect_to :action => index
  end
  
  def new
    @page_title += " - Upload New File"
    if request.xhr? or request.post?
      begin
        content_type = params[:file][:file].content_type.strip.to_s
        @file = content_type.include?("image") ? Image.new(params[:file]) : Resource.new(params[:file])
        @file.name = params[:label]
        @file.content_type = content_type
        @file.size = params[:file][:file].size
        @file.tag(params[:tags], :clear => true)
        #@file.project_id = params[:resource][:project_id]
        unless @file.save
          raise "An error prevented this file from being uploaded:<br /><small>#{@file.errors.full_messages.join("<br />")}</small>"
        end
        @file.tag(params[:tags], :clear => true)
        redirect_to :action => "index"
      rescue Exception => e
        flash[:notice], flash[:class] = e, "bad"
        redirect_to :action => "index"
      end
    else
      @file = Resource.new
    end
    
  end
  
  def download
    @file =  @homebase.files.find_by_permalink(params[:permalink])
    AccessLog.create(:resource_id => params[:id], :request => request.env["REQUEST_URI"], :ip => request.env["REMOTE_ADDR"],:referrer => request.env["HTTP_REFERER"],:user_agent => request.env["HTTP_USER_AGENT"],:language => request.env["HTTP_ACCEPT_LANGUAGE"],:host => request.env["HTTP_HOST"])
    if @file.class == Image
      case params[:size]
      when "screen"
        redirect_to File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}", "images", @file[:id].to_s, "screen", @file[:file])
      when "thumbnail"
        redirect_to File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}", "images", @file[:id].to_s, "thumb", @file[:file])
      else
        redirect_to File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}", "images", @file[:id].to_s, @file[:file])
      end
    else
      loc = File.join("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}", "files", @file[:id].to_s, @file[:file])
      redirect_to loc
      #render :text =>  loc.inspect, :layout => false and return
    end
  end

  def delete
    #if request.post?
      file = @homebase.files.find_by_permalink(params[:permalink])
      file.destroy
      flash[:notice], flash[:class] = "File deleted", "good"
      redirect_to :action => "index"
    #end
  end
  
  def edit_tags
    if request.xhr?
      @file = @homebase.files.find_by_permalink(params[:permalink])
      @file.tag(params[:tags], :clear => true)
      render :text => @file.tag_names.join(", "), :layout => false
    end
  end
  
  
  private
  def page_title
    @page_title = "Files"
  end
  
end
