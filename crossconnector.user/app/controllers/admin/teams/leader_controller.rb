class Admin::Teams::LeaderController < ApplicationController
  
  before_filter :login_required
  before_filter :page_title
  def page_title
    @page_title = "Leaders"
  end
  
  def index
  end

  def show
    #return if protect_from_leaders(:action => "leaders")
    @leader = User.find(params[:id])
    @page_title = "Leader - #{@leader.name.to_s}"
  end
  
  
  def new
    #protect_from_leaders
    @page_title += " - New Leader"
    @leader = Leader.new(@params[:leader])
    case request.method
    when :post
      begin
          @leader.created_by = User.current_user.id
          #@leader.homebase_subdomain = "none"
          @leader.terms = "1"
          @leader.homebase_id = Homebase.current_homebase.id
          if @leader.save
            if @params[:send_email] == "yes"
              SystemMailer.deliver_leader_welcome(@leader) or raise "Email not sent"
            end
            flash[:notice], flash[:class] = "Leader saved", "good"
          else
            raise "Leader not saved."
          end
        redirect_to :action => "index" and return
      rescue Exception => e
        flash[:notice], flash[:class] = "There was an error saving this leader.<ul>#{@leader.errors.full_messages.collect{ |e| "<li>#{e}</li>" }}</ul>", "bad"
      end
    end
  end

  def edit
    #return if protect_from_leaders(:action => "leaders")
    @leader = @homebase.leaders.find(params[:id])
    @page_title += " - #{@leader.name.to_s}"
    
    #if User.current_user.id == Homebase.current_homebase.created_by.id
      case request.method
      when :post   
        begin        
          @leader.update_attributes(params[:leader])
          #@leader.change_password(params[:leader][:password])
          #@leader.change_password(@params['leader']['password'])
          flash[:notice], flash.now[:class] = "Leader saved", "good"
        rescue
          flash[:notice], flash.now[:class] = "An error occurred", "bad"
          redirect_to :action => "leaders" and return
        end
      end
    #else
    #  redirect_to(:action => "show_leader", :id => @leader.id) and return    
    #end
    
  end

  def delete
    # Delete Leaders
    # It's named this way to comply with shared/delete_confirmation, which looks for the action named "delete"
    # Doesn't actually delete the record, but sets the values to deleted.
    # This is so that objects created by the leader will still be associated with the name.
    # The only time leaders are deleted is if the homebase is deleted, and it cascades. 
    
    return if protect_from_leaders(:action => "index")
    case request.method
    when :post
      
      begin
        #raise "Sorry, you are not allowed to delete this leader" if User.current_user.id = Homebase.current_homebase.created_by.id
        
        @user = @homebase.leaders.find(params[:id])
        raise "An error occurred while deleting this leader." unless @user.update_attributes(:deleted => 1, :deleted_at => Time.now)
        raise "An error occurred while deleting this leader." unless @user.update_attributes(:username => nil, 
                                :email => nil, 
                                :salt => nil, 
                                :salted_password => nil, 
                                :can_edit_messages => 0, 
                                :can_edit_projects => 0, 
                                :can_edit_files => 0, 
                                :can_edit_addresses => 0)
        flash[:notice], flash[:class] = "Leader deleted", "good"
        
      rescue Exception => e
        flash[:notice], flash[:class] = e, "bad"
      end
    end
    redirect_to :action => "index"
  end
  
  def resend_welcome_email
    if request.xhr?
      begin
        @leader = Leader.find(params[:id])
        SystemMailer.deliver_leader_welcome(@leader)
        render :text => "Welcome email re-sent to #{@leader.email}"
      rescue Exception => e
        render :text => "There was an error sending the email.<ul>#{@leader.errors.full_messages.collect{ |e| "<li>#{e}</li>" }}</ul>"
      end
    end
  end
end
