class Admin::EventController < ApplicationController
  
  before_filter :login_required
  before_filter :page_title
  
  def new
    @event = Event.new(params[:event])
    if request.xhr? or request.post?
      begin
        set_duration
        if @event.save
          # Set the last_event_date in the session as a convenience
          session[:last_event] = @event.start_date
          render :partial => "admin/event/event_list", :layout => false, :object => @event.project
        else
          raise "An error occurred, and this event was not saved."
        end
      rescue Exception => e
        flash[:error] = e
        render :partial => "/shared/error", :layout => false
      end      
    end
  end
  
  def edit
    @event = Event.find(params[:event][:id])
    if request.xhr? or request.post?
      set_duration
      @event.update_attributes(params[:event])
      # @project = Project.find(@event.project_id)
      render :partial => "admin/event/event_list", :layout => false, :object => @event.project
      #render :nothing => true, :layout => false
    end
  end
  
  
  def set_duration
    if params[:event][:duration_n] and params[:event][:duration_unit]
      n = params[:event][:duration_n].to_i
      unit = params[:event][:duration_unit].to_s.downcase
      case unit
      when "minutes"
        @event.end_date = @event.start_date + n.minutes
      when "hours"
        @event.end_date = @event.start_date + n.hours  
      when "days"
        @event.end_date = @event.start_date + n.days
      when "weeks"
        @event.end_date = @event.start_date + n.weeks
      when "months"
        @event.end_date = @event.start_date + n.months
      when "years"
        @event.end_date = @event.start_date + n.years
      else
        @event.end_date = nil
      end
    end
    
  end

  
  
  def open_event_form
    # State = "new" or "edit"
    @event = params[:state] == "edit" ? Event.find(params[:id]) : Event.new
    @event.project_id = params[:project_id] if params[:project_id]
    render :partial => "/admin/event/#{params[:state]}_event", :layout => false, :object => @event
    #render :text => "foo", :layout => false
  end

  def delete
    @event = Event.find(params[:id])
    @event.destroy
    if request.xhr?
      render :nothing => true, :layout => false 
    end
    
  end
  
  private
  
  def page_title
    @page_title = "Plan projects &rarr; Event Details"
  end

  #def setup_connection
    # This ugly bit of code deletes the value for the connected_to form field if it is 0
    # Or sets it to a User object if it is not 0
    
    #@params[:event].delete('connected_to') if !@params[:event].nil? and @params[:event][:connected_to].to_i == 0
    #@params[:event][:connected_to] = User.find(@params[:event][:connected_to]) if @request.post? and !@params[:event][:connected_to].nil?
  #end
  
end
