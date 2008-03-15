class Admin::AccountController < ApplicationController

  before_filter :login_required, :except => [:login, :login_with_token, :do_login_with_token, :forgot_password]
  before_filter :page_title
  helper :application, 'admin/teams'
  #layout "default"
  #theme "orange"
  
  #layout "login", :except => [:index, :profile, :details, :password, :editors, :new_editor, :edit_editor, :subscription, :update_subscription, :cancel]
  layout "application", :except => [:login]
  
  def login
    case request.method
    when :post, :xhr
      if session[:user] = User.authenticate(params[:user][:username], params[:user][:password])
        flash[:notice], flash[:class] = "Login successful. Welcome to your homebase!", "good"
        catch_missing_subscription
        catch_lapsed_account
        redirect_back_or_default :controller => "homebase" 
      else        
        flash.now[:notice], flash[:class] = "Sorry, we didn't recognize your email address or password.", "bad"
        @login = params[:email]
        render :layout => "public_login"
      end
    else
      render :layout => "public_login"
    end
  end
  
  # This intermediate step seems to be necessary to set up the session
  def login_with_token
    redirect_to :action => :do_login_with_token, :token => params[:t]
  end
  
  def do_login_with_token
    begin
      if session[:user] = User.authenticate_with_token(params[:token])
        get_current_user
        flash[:notice], flash[:class] = "Signup successful. Welcome to your new CrossConnector homebase!", "good"
        catch_lapsed_account
        redirect_to :controller => "/admin" and return
      else
        raise "Sorry, something happened and we could not log you in automatically. Please enter your username and password to try again."
      end
    rescue Exception => e
      flash[:notice], flash[:class] = e, "bad"
      redirect_to :action => "login" and return
    end
  end
  
  def catch_lapsed_account
    if session[:user].homebase.subscription.lapsed?
      previous_level = session[:user].homebase.subscription.plan.name
      
      session[:user].homebase.subscription.plan = SubscriptionPlan.find_by_name("Free")
      session[:user].homebase.subscription.save
      
      reason = session[:user].homebase.subscription.invoices.empty? ? "Your free trial of the #{previous_level} version has ended" : "We were unable to charge your credit card"
      flash[:notice] += "<p><strong>Notice: #{reason}, so your account has automatically been downgraded to the Free version. </strong></p>
                        <p><small>You can still <a href=\"/admin/account\">upgrade your account</a> at any time.<br />
                        If you'd like to extend your trial period, please email <a href=\"/mailto:support@crossconnector.com\">support@crossconnector.com</a>.</small></p>"
      update_session
    end
  end
  
  def catch_missing_subscription
    # If no subscription, set to free.
    return Subscription.create(:homebase_id => @homebase.id, :price => 0, :subscription_plan_id => SubscriptionPlan.find_by_name("Free")) if @homebase.subscription.nil? 
    # If no plan, set to free
    return @homebase.subscription.plan = SubscriptionPlan.find_by_name("Free") if @homebase.subscription.plan.nil?
  end
  
  
  def index
    @page_title = "Your Account"
    @homebase = Homebase.find(Homebase.current_homebase.id)
    @user = User.find(User.current_user.id)
    @plans = SubscriptionPlan.find(:all, :order => "price DESC", :conditions => "visible = '1'")
    @priveleges = SubscriptionPlanPrivelege.find(:all, :order => "id ASC")
    
    #@user.subscription_plan_id ||= 1
    #render :layout => "application"
  end
  
  def profile
    protect_from_leaders :action => "index" 
    @user = User.find(User.current_user.id)
    @homebase = Homebase.find(Homebase.current_homebase.id)
    if request.post?
      begin
        @homebase.update_attributes(params[:homebase])
        @homebase.save
        update_session
        flash.now[:notice], flash.now[:class] = "Your profile has been updated!", "good"
      rescue Exception => e
        flash.now[:notice], flash.now[:class] = "An error occurred updating your profile. (#{e})", "bad"
      end
    end
    
    # @page_title = "Site Profile"
    #render :layout => "application"
  end
  
  def your_info
    @user = User.find(User.current_user.id)
    if request.post?
      begin
        @user.update_attributes(params[:user])
        raise "An error occurred when saving your info:<br /><small>#{@user.errors.full_messages.join("<br />")}</small>" unless @user.valid?
        update_session
        flash.now[:notice], flash.now[:class] = "Your information has been updated", "good"
      rescue Exception => e
        flash.now[:notice], flash.now[:class] = e, "bad"
      end
    end
  end
  
  def invoice
    @invoice = Invoice.find(params[:number])
    @page_title = "Invoice ##{@invoice.id}"
    render :layout => "invoice"
  end

  # Change current user's password and send a confirmation email
  def password
    
    if request.post?
      begin
        @user = User.find(User.current_user.id)
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.save
          # Send confirmation email here
          update_session
          flash[:notice], flash[:class] = "Password changed successfully", "good"
          redirect_to :controller => "account", :action => "index" and return
        else
          raise "Sorry, your password couldn't be changed."
        end
      rescue Exception => e
        flash.now[:notice], flash.now[:class] = "#{e}<br /><small>#{@user.errors.full_messages.join("<br />")}</small>", "bad"
        #redirect_to :controller => "account", :action => "password" and return
      end
    end

  end
  
  def editors
    @homebase = Homebase.find(Homebase.current_homebase.id)
    @editors = @homebase.editors
    @owner = @homebase.created_by
  end
  
  
  def new_editor
    protect_from_leaders :action => "editors" 
    @page_title = "New Editor"
    @editor = Editor.new(@params[:editor])
    case request.method
    when :post
      begin
          @editor.created_by = User.current_user.id
          @editor.homebase_subdomain = "none"
          @editor.terms = "1"
          @editor.homebase_id = Homebase.current_homebase.id
          if @editor.save
            if @params[:send_email] == "yes"
              SystemMailer.deliver_editor_welcome(@editor) or raise "Email not sent"
            end
            flash[:notice], flash[:class] = "Editor saved", "good"
          else
            raise "Editor not saved."
          end
        redirect_to :action => "editors" and return
      rescue Exception => e
        flash[:notice], flash[:class] = "There was an error saving this editor.<ul>#{@editor.errors.full_messages.collect{ |e| "<li>#{e}</li>" }}</ul>", "bad"
      end
    end
    #render :layout => "application"
  end
  
  def resend_welcome_email
    if request.xhr?
      begin
        @editor = Editor.find(params[:id])
        SystemMailer.deliver_editor_welcome(@editor)
        render :text => "Welcome email re-sent to #{@editor.email}"
      rescue Exception => e
        render :text => "There was an error sending the email.<ul>#{@editor.errors.full_messages.collect{ |e| "<li>#{e}</li>" }}</ul>"
      end
    end
  end
  
  def edit_editor
    
    return if protect_from_leaders(:action => "editors")
    
    @editor = User.find(params[:id])
    @page_title = "Edit - #{@editor.name.to_s}"
    
    if User.current_user.id == Homebase.current_homebase.created_by.id
      case request.method
      when :post   
        begin        
          @editor.attributes = params[:editor]
          #@editor.change_password(params[:editor][:password])
          #@editor.change_password(@params['editor']['password'])
          @editor.save
          flash[:notice], flash.now[:class] = "Editor saved", "good"
        rescue
          flash[:notice], flash.now[:class] = "An error occurred", "bad"
          redirect_to :action => "editors" and return
        end
      end
    else
      redirect_to(:action => "show_editor", :id => @editor.id) and return    
    end
    
    #render :layout => "application"
  end
  
  def show_editor
    
    return if protect_from_leaders(:action => "editors")
    
    @editor = User.find(params[:id])
    @page_title = "Editor - #{@editor.name.to_s}"
    #render :layout => "application"
  end
  

  

  
  def logout
    kill_session
    flash[:notice], flash[:class] = "You have successfully logged out.", "good"
    redirect_to :controller => "/public" and return
    #redirect_to(@request.protocol + @request.host + url_for(:controller => "/account", :action => "login", :only_path => true)) and return false
  end

  def welcome
  end

  def forgot_password
    if request.post?
      begin
        @user = User.find_by_email_and_homebase_id(params[:user][:email], Homebase.current_homebase.id)
        SystemMailer.deliver_forgot_password(@user)
        flash.now[:notice], flash.now[:class] = "Ok, we sent it! You should receive it by email in a second or two.", "good"
      rescue
        flash.now[:notice], flash.now[:class] = %Q{Sorry, we couldn't find that email address. Please email <a href="mailto:support@crossconnector.net">support@crossconnector.net</a> for assistance}, "bad"
      end
    end
    render :layout => "public_login"
  end
  
  def subscription
    protect_from_leaders(:action => "index")
    @user.generate_security_token(0.5) # Expires in 1/2 hour
    #render :layout => "application" and return
    redirect_to "#{ RAILS_ENV == "production" ? "https" : "http" }://secure.#{App::CONFIG[:app_domain]}/account/#{@homebase.subdomain}/subscribe/#{params[:plan]}/#{@user.security_token}" and return
  end
  
  def update_subscription
    protect_from_leaders(:action => "index")
    @homebase.update_subscription_plan(params[:plan][:id])
    redirect_to :controller => "/admin/account"
  end
  
  def cancel
    protect_from_leaders(:action => "index")
    
    @page_title = "Cancel Your Account"
    case request.method
    when :post
      begin
        if @homebase = Homebase.find(:first, :conditions => ["id = ? and created_by = ?", Homebase.current_homebase.id, User.current_user.id])
          # Email notification to support...
          SystemMailer.deliver_cancellation_notification(@homebase)
          # Send confirmation email...
          SystemMailer.deliver_cancellation_confirmation(@homebase) or raise "Email not sent"
          # Cancel billing...
          #   this is done by hand for now
          # Destroy homebase (cascades)...
          @homebase.destroy
          # Log out...
          kill_session
          # And redirect back to www...
          redirect_to "http://www.#{App::CONFIG[:app_domain]}" and return
        else
          raise "An error occurred, and we could not canncel this account. Please email support@crossconnector.com for assistance."
        end
      rescue Exception => e
        flash[:notice], flash[:class] = e, "bad"
      end
    end
  end
  
  
  private
  

  
  def page_title
    @page_title = "Your Account"
  end
  
  def update_session
    User.current_user = @user if @user
    Homebase.current_homebase = @homebase if @homebase
  end
  
  def kill_session
    session[:user] = nil
    User.current_user = nil
  end
  
end