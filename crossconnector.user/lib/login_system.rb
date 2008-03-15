module LoginSystem
  
  def foo(str)
    "Foo! #{str}"
  end
  
  protected
  
  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights  
  # example:
  #
  #  # only allow nonbobs
  #  def authorize?(account)
  #    account.login != "bob"
  #  end
  def authorize?(user)
     User.current_user.homebase.id == Homebase.current_homebase.id
  end
  
  # overwrite this method if you only want to protect certain actions of the controller
  # example:
  # 
  #  # don't protect the login and the about method
  #  def protect?(action)
  #    if ['action', 'about'].include?(action)
  #       return false
  #    else
  #       return true
  #    end
  #  end
  def protect?(action)
    true
  end
   
  # login_required filter. add 
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management. 
  # for finer access control you can overwrite
  #   
  #   def authorize?(account)
  # 
  def login_required
    # return true
    
    #if not protect?(action_name)
    #  return true  
    #end
    
    if User.current_user and authorize?(User.current_user)
      return true
    end
    
    # store current location so that we can 
    # come back after the user logged in
    store_location
  
    # call overwriteable reaction to unauthorized access
    access_denied and return false
    return false 
  end

  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
    redirect_to(@request.protocol + @request.host + url_for(:controller => "/admin/account", :action => "login", :only_path => true)) and return false
    #redirect_to(:controller => "/account", :action => "login") and return false
  end  
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    @session[:return_to] = @request.request_uri
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      #redirect_to(@request.protocol + @request.host + url_for(default, :only_path => true)) and return true
      redirect_to default and return true
    else
      redirect_to(@request.protocol + @request.host + url_for(@session[:return_to], :only_path => true)) and return true
      #redirect_to @session[:return_to] and return true
      session[:return_to] = nil
    end
  end
  
  
  
  def user?
    return true if User.current_user
  end
  
end
