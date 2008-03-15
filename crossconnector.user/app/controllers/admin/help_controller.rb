class Admin::HelpController < ApplicationController
  before_filter :login_required
  
  def index
    @page = Page.find_by_permalink("help")
    @page_title = "Help"
  end
end
