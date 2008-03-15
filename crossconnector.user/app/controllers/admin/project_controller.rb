class Admin::ProjectController < ApplicationController

  before_filter :login_required
  before_filter :page_title
  before_filter :check_account_limits, :only => ["new"]
  helper "admin/event"

  @@objects_per_page = App::CONFIG[:objects_per_page]
  
  def index
    @related_tags = Project.find_tags_for_homebase unless @homebase.projects.empty?
    
    @project_pages = Paginator.new self, @homebase.projects.count, @@objects_per_page, @params['page']
    @projects = @homebase.projects.find(:all, :limit => @project_pages.items_per_page, :offset => @project_pages.current.offset)
    
    @page_title = "#{@projects.size} Projects"
  end
  
  
  def check_account_limits
    #if @homebase.projects.count >= @homebase.plan.priveleges.find(1).plan_limit.to_i and @homebase.plan.priveleges.find(1).plan_limit.to_i != 0
    if !@homebase.within_projects_limit?
      flash[:notice], flash[:class] = "Sorry, you have reached your plan's limit of #{@homebase.plan.priveleges.find(1).plan_limit.to_s} projects. <br /><small><a href=\"#{url_for(:controller => "/account#subscription_plans")}\">You must upgrade</a> to add more projects.</small>", "bad"
      redirect_to :action => "index"
    end
  end
  
  def show
    #begin
      @project = @homebase.all_projects.find_by_permalink(@params[:permalink])
      @page_title += " - #{@project.name}"
      
      if @project.tags.empty?
        @related_files = @project.files
      else
        @tags = @project.tags.collect {|t| t.name}.join(",") 
        @tagged_files = @homebase.files.find_tagged_with(:any => @tags, :separator => ",", :homebase => true)
        @related_files = @project.files - @tagged_files + @tagged_files        
      end
      
    #rescue
    #  flash[:notice], flash[:class] = "The project \"#{@params[:permalink]}\" could not be found", "bad"
    #  redirect_to :action => "index"
      #flash[:error] = "Sorry, that project is not available. "
      #render :partial => "shared/error", :layout => "application"
    #end
  end
  
  def events
    begin
      @project = @homebase.projects.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]])
      @event = Event.new(:project_id => @project.id)
      @page_title += " - #{@project.name}"
    rescue Exception => e
      flash[:notice], flash[:class] = "Unable to edit this project.", "bad"
      redirect_to :action => "show", :permalink => params[:permalink]
    end
  end
  
  def new
    @page_title += " - New Project"
    @project = Project.new(@params[:project])
    case @request.method
    when :post
      begin
        if @project.save
          @project.tag(params[:tags])
          # Send email if either addresses OR groups are checked...
          SystemMailer.deliver_project(@project) unless (@project.addresses.empty? and @project.groups.empty?)
          flash[:notice], flash[:class] = "Project saved", "good"
          redirect_to :action => "show", :permalink => @project.permalink
        else
          raise "An error occurred when saving your project.<br /><small>#{@project.errors.full_messages.join("<br />")}</small>"
        end
      rescue Exception => e
        flash.now[:notice], flash[:class] = e, "bad"
      end
    end
  end
  

  
  def edit
    @page_title = "Edit Project"
    begin
      @user = User.current_user
      @project = @homebase.projects.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]])
      #@image = Image.new(params[:image])
      if request.post?
        begin
          params[:project][:group_ids] ||= []
          params[:project][:address_ids] ||= []
          @project.tag(params[:tags], :clear => true)
          
          
          @project.update_attributes(params[:project])
          
          #@project.private_checkbox = 0
          #@project.save
          
          #if params[:image]
          #  @image.save
          #end
          
          flash[:notice], flash[:class] = "Project saved", "good"
          
          if params[:project][:resend_email].to_i == 1 and (!@project.addresses.empty? or !@project.groups.empty?)
            SystemMailer.deliver_project(@project) 
            flash[:notice] << " and email re-sent"
          end
          redirect_to :action => "show", :permalink => @project.permalink and return
        rescue Exception => e
          flash[:notice], flash[:class] = "An error occurred, and your project was not saved. (#{e})", "bad"
        end
      end
    rescue
      flash[:notice], flash[:class] = "Unable to edit this project.", "bad"
      redirect_to :action => "show", :permalink => params[:permalink] and return
    end
  end
  
  def tags
    if request.xhr?
      begin
        @project = Project.find(:first, :conditions => ["permalink = ?", params[:permalink]])
        @project.tag(params[:tags], :clear => true)
        render :partial => "/shared/tags_list", :object => @project, :layout => false
      rescue Exception => e
        render :text => "Sorry, your tags could not be updated because an error occurred.", :layout => false
      end
    end
  end
  
  def user_can_edit_projects?
    return true if User.current_user.class == User 
    return true if User.current_user.can_edit_projects == 1
    return false
  end
  
  def redirect_unless_user_can_edit_projects(*args)
    if !user_can_edit_projects?
      redirect_to *args
      flash[:notice] = "Sorry, you are not allowed to edit this project."
    end
  end
  
  def show_project_form
    if user_can_edit_projects? and @project = @homebase.project.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]])
      render :partial => "form", :object => @project, :layout => false
    else
      render :text => "Sorry, you are not allowed to edit this project.", :layout => false
    end
  end
  
  def show_delete_form
    if user_can_edit_projects? and @object = @homebase.project.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]])
      @title = @object.name
      render :partial => "shared/delete_confirmation", :object => @object, :layout => false
    else
      render :text => "Sorry, you are not allowed to delete this project.", :layout => false
    end
  end

  def delete 
    if request.xhr? or request.post?
      begin
        
        @project = @homebase.all_projects.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]])
        begin
          @project.destroy
          flash[:notice], flash[:class] = "Project \"#{@project.name}\" deleted", "good"
        rescue
          flash[:notice], flash[:class] = "An error occurred, and this project was not deleted.", "bad"
        end
      rescue
        flash[:notice], flash[:class] = "Sorry, you are not allowed to delete this project.", "bad"
      end
    end
    redirect_to :action => "index"
  end
  
  
  def show_archive_form
    if user_can_edit_projects? and @project = @homebase.projects.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]]) and request.xhr?
      render :partial => "admin/project/archive_form", :object => @project, :layout => false
    else
      render :text => "Sorry, you are not allowed to archive this project.", :layout => false
    end
  end
  
  def archive_project
    begin
    
    if User.current_user.can_edit_projects? and request.post? and @project = @homebase.all_projects.find(:first, :conditions => ["permalink = ?", params[:permalink]])

      if @project.archived?
        @project.update_attribute(:archived, 0)
        flash[:notice], flash[:class] = "Project un-archived", "good"
        redirect_to :action => "show", :permalink => @project.permalink and return
      else
        @project.update_attribute(:archived, 1)
        flash[:notice], flash[:class] = "Project archived", "good"
        redirect_to :action => "show", :permalink => @project.permalink and return
      end
    else
      raise "Could not change project status."
    end
    rescue Exception => e
      flash[:notice], flash[:class] = e, "bad"
      redirect_to :action => "show", :permalink => params[:permalink] and return
    end
  end
  
  
  def duplicate
    
    unless @homebase.can_create_projects?
      flash[:notice], flash[:class] = "Unable to duplicate this project. <small>You already have #{@homebase.projects.count} project#{"s" if @homebase.projects.count > 1} out of a total of #{@homebase.projects_limit} included in <a href=\"/admin/account\">your plan</a>.<br />You'll need to <a href=\"/admin/account\">upgrade</a> in order to create any more projects.</small>", "bad"
      redirect_to :back and return
    end 
    
    begin
      @project = @homebase.all_projects.find_by_permalink(params[:permalink]) or raise("Unable to duplicate this project.")
      @page_title = "Project &mdash; #{@project.name}"
      @project.name += " Copy"
      @start_date = @project.all_events.first.start_date rescue Date.today
      if request.post?        
        Project.transaction(@project) do
          begin
            @p2 = @project.clone
            @p2.name = params[:project][:name]
            @p2.archived = 0 if @p2.archived?
            @p2.save
            
            unless @project.all_events.nil? and @project.all_events.empty?
              
              @date_shift = Time.mktime(params[:date][:year], params[:date][:month], params[:date][:day]) if params[:date] rescue nil
              @date_diff = (@date_shift - @project.all_events.first.start_date) rescue nil
              @start_date = @project.all_events.first.start_date + @date_diff rescue nil
              
              for event in @project.all_events
                e2 = event.clone
                e2.project_id = @p2.id
                e2.start_date = e2.start_date + @date_diff if e2.start_date
                e2.end_date = e2.end_date + @date_diff if e2.end_date
                e2.save
              end
            end

            flash[:notice], flash[:class] = "Project duplicated", "good"
          rescue
            raise "Sorry, an error occurred while duplicating this project."
          end
        end
        redirect_to :action => :show, :permalink => @p2.permalink
      end
    rescue Exception => e
      flash[:notice], flash[:class] = e, "bad"
    end
  end
  
  
  
  private
  def page_title
    @page_title = "Projects"
  end
  
  def auto_complete_responder_for_users(value)
    @users = User.find(:all, :conditions => ['LOWER(name) LIKE ?', '%' + value.downcase + '%'], :order => 'name ASC', :limit => 10)
    render :partial => "connection_popup", :object => @users, :layout => false
  end
  
  
  def setup_connection
    # This ugly bit of code deletes the value for the connected_to form field if it is 0
    # Or sets it to a User object if it is not 0
    
    @params[:project].delete('connected_to') if !@params[:project].nil? and @params[:project][:connected_to].to_i == 0
    @params[:project][:connected_to] = User.find(@params[:project][:connected_to]) if @request.post? and !@params[:project][:connected_to].nil?
  end
end
