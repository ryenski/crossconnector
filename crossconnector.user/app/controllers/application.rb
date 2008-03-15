require 'login_system'

# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base
  
  include LoginSystem
  include ExceptionNotifiable
  
  #handles ::ActionController::RoutingError, :with => :render_404
  
  attr_writer :current_homebase
  attr_reader :current_homebase
  attr_writer :current_user
  attr_reader :current_user

  before_filter :get_current_homebase
  before_filter :get_current_user
  before_filter :set_session_domain
  
  # Thanks to: http://wiki.rubyonrails.com/rails/show/HowToUseSubdomainsAsAccountKeys      
  # Another way: 
  # { |c| Homebase.current_homebase = Homebase.find_first(["subdomain = ?", c.request.subdomains.first]) unless (App::CONFIG[:restricted_subdomains].include?(c.request.subdomains.first.to_s) or c.request.subdomains.first.nil?) } 
  # Uses request.subdomains.last so that it catches www.subdomain.crossconnector as well
  def get_current_homebase
    begin
      if (App::CONFIG[:reserved_subdomains].include?(@request.subdomains.last.to_s) or @request.subdomains.last.nil?)
        Homebase.current_homebase = Homebase.find_by_subdomain("example")
      else
        Homebase.current_homebase = Homebase.find_by_subdomain(@request.subdomains.last)
      end
      @homebase = Homebase.current_homebase
      @page_title = @homebase.name
    rescue Exception => e
      cant_find_homebase(e)
    end
  end
  
  # get_current_user sets up the current_user variable in the User model. Requires a cattr_accessor variable
  # in the User model in order to work. 
  # Help Found here: http://livsey.org/2005/07/16/adding_created_by_and_updated_by_to_rails/
  # and here: http://wiki.rubyonrails.com/rails/show/Howto%20Add%20created_by%20and%20updated_by
  # before_filter { |c| User.current_user = User.find(c.session[:foo]) unless c.session[:foo].nil? }
  def get_current_user
    User.current_user = session[:user].nil? ? nil : session[:user]
    @user = User.current_user
  end
  
  
  # Setting the Session_domain makes sure the session is only applicable to the current subdomain
  def set_session_domain
    ::ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS.update(:session_domain => "#{@request.subdomains.first}.#{@request.domain}")
  end
  
  # Generates a filled in @user local variable from the currently logged in user
  def generate_filled_in
    @user = session[:user]
    @homebase = Homebase.current_homebase
    #if @request.get?
    #  render
    #end
  end
  
  # Raise the 404 error page if a requested homebase does not exist. 
  def cant_find_homebase(e=nil)
    raise ActiveRecord::RecordNotFound
  end

  
  # Thanks to Tobias Lutke for his work on Typo
  # The theme code is borrowed from Typo
  def theme_layout
    Theme.current.layout
  end
  
  def protect_from_leaders(action=:index)
    redirect_to action and return unless @user.can_edit_leaders?
    #return false
  end
  
  protected
  
  def default_url_options(options)
    #{ :host => @request.host } unless @request.nil?
  end

end