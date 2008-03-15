class Admin::MessageController < ApplicationController

  before_filter :login_required
  before_filter :page_title
  
  @@objects_per_page = App::CONFIG[:objects_per_page]
  
  def index
    @message_pages = Paginator.new self, @homebase.messages.count, @@objects_per_page, @params['page']
    @messages = @homebase.messages.find(:all, :limit => @message_pages.items_per_page, :offset => @message_pages.current.offset)    
  end
  
  def show
    
    begin
      @message = @homebase.all_messages.find_protected(:first, :conditions => ["permalink = ?", params[:permalink]])
      @page_title += " - #{@message.subject}"
      @cookies = cookies
      @cookies[:comment_name] ||= User.current_user.name.to_s unless User.current_user.nil?
      #@cookies[:comment_url] ||= link_to_homebase(User.current_user) unless User.current_user.nil?
      @cookies[:comment_email] ||= User.current_user.email unless User.current_user.nil?
      @comments_count = @message.comments.size
      #@page_title = @message.subject
    rescue
      flash[:notice], flash[:class] = "The message that you requested is not available.", "bad"
      redirect_to :action => "index"
    end
  end

  def new
    @page_title += " - New Message"
    @received_projects = Project.find_received_projects
    setup_project
    @message = Message.new(params[:message])
    
    if @request.post?
      begin
        params[:message][:group_ids] ||= []
        params[:message][:address_ids] ||= []
        
        if @message.save
          flash[:notice], flash[:class] = "Message saved", "good"
          @message.tag(params[:tags])          
          if !@message.addresses.empty? or !@message.groups.empty? # and params[:send_email] 
            SystemMailer.deliver_message(@message)
            flash[:notice] << " and email sent"
          end
          redirect_to(:action => "show", :permalink => @message.permalink)
        end
      rescue
        flash[:notice], flash[:class] = "Message not saved", "bad"
      end
    end
  end


  def edit
    @page_title += " - Edit Message"
    begin 
      #@user = User.find(User.current_user.id)
      #@received_projects = Project.find_received_projects
      @message = @homebase.all_messages.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]]) 
      setup_project
      @preselected_project = @message.project.id unless @message.project.nil?
      if request.post?
        begin
          params[:message][:group_ids] ||= []
          params[:message][:address_ids] ||= []
          @message.tag(params[:tags], :clear => true)
          @message.update_attributes(params[:message])
          flash[:notice], flash[:class] = "Message saved", "good"
          if params[:message][:resend_email].to_i == 1 and (!@message.addresses.empty? or !@message.groups.empty?)
            SystemMailer.deliver_message(@message) 
            flash[:notice] << " and email re-sent"
          end
          redirect_to(:action => "show", :permalink => @message.permalink)
        rescue Exception => e
          flash[:notice], flash[:class] = "Message not saved (#{e}).<br /><small>#{@message.errors.full_messages.join("<br />")}</small>", "bad"
        end
      end
    rescue
      flash[:error], flash[:class] = "Access denied", "bad"
      redirect_to :action => "show", :permalink => params[:permalink] and return
    end
  end
  
  def delete
    #@page_title += " - Delete Message"
    if request.post?
      begin
        @object = @homebase.messages.find_protected_for_editing(:first, :conditions => ["permalink = ?", params[:permalink]])
        @object.destroy
        flash[:notice], flash[:class] = "Message deleted", "good"
        redirect_to :action => "index"
      rescue
        flash[:notice], flash[:class] = "An error occurred while deleting this message.", "bad"
        redirect_to :action => "show", :permalink => params[:permalink]
      end
      
    else
      flash[:notice], flash[:class] = "Sorry, you are not allowed to delete this message.", "bad"
      redirect_to :action => "show", :permalink => params[:permalink]
    end
    
  end

  
  def tags
    if request.xhr?
      begin
        @message = Message.find_by_permalink(params[:permalink])
        @message.tag(params[:tags], :clear => true)
        render :partial => "/shared/tags_list", :object => @message, :layout => false
      rescue Exception => e
        render :text => "Sorry, your tags could not be updated because an error occurred.", :layout => false
      end
    end
  end
  

  
  def observe_project_select
    if request.xhr?
      begin
        
        @project = Project.find_by_id(params[:project_id])
        if @project.private?
          render :partial => "shared/forms/private_project_notice", :layout => false#, :object => @project
        else
          render :nothing => true, :layout => false
        end
      
      rescue
        render :nothing => true, :layout => false
      end
      
    end
  end

  
  
  
  
  private
  def page_title
    @page_title = "Messages"
  end
  
  def setup_project
    # deletes the value for the connected_to form field if it is 0
    # Or sets it to a User object if it is not 0
    
    @params[:message].delete('project') if !@params[:message].nil? and @params[:message][:project].to_i == 0
    @params[:message][:project] = Project.find(@params[:message][:project]) if @request.post? and !@params[:message][:project].nil?
  end
  
end
