class Admin::TeamsController < ApplicationController
  
  before_filter :login_required
  before_filter :page_title
  helper "admin/account"
  
  def index
    #@user = User.find(session[:user].id)
    @homebase = Homebase.find(Homebase.current_homebase.id)
    @group = Group.new
    @group.name, @group.addresses = "All Addresses", @homebase.addresses
    session[:last_group] = nil
  end
  
  def get_address_detail
    @address = @homebase.addresses.find(params[:id])
    render :partial => "admin/teams/addressbook/address_detail", :object => @address, :layout => false
  end
  
  def update_address
    @address = @homebase.addresses.find(params[:address][:id])
    # @user = User.find(session[:user].id)
    if request.post? or request.xhr?
      params[:address].delete("group_ids")
      params[:address].delete("address1") if params[:address][:address1] == "Address line 1"
      params[:address].delete("address2") if params[:address][:address2] == "Address line 2"
      params[:address].delete("city") if params[:address][:city] == "City"
      params[:address].delete("state") if params[:address][:state] == "State/Province"
      params[:address].delete("postal") if params[:address][:postal] == "Zip/Postal"
      params[:address].delete("country") if params[:address][:country] == "Country"
      @address.update_attributes(params[:address])
      render :partial => "admin/teams/addressbook/address_detail", :object => @address, :layout => false
    end 
  end
  
  def update_group
    @group = Group.find(params[:group][:id])
    @group.update_attributes(params[:group]) if request.post? or request.xhr?
    render :partial => "admin/teams/addressbook/addressbook", :layout => false, :object => @homebase
  end
  
  #def delete_group
  #  @group = Group.find(params[:group][:id])
  #  if request.post? or request.xhr?
  #    @group.delete
  #  end    
  #end
  
  def add_group
    @group = Group.new(params[:add_group])
    begin
      @group.save
      session[:last_group] = @group.id
      render :partial => "admin/teams/addressbook/group_list_item", :object => @group, :layout => false
    rescue
      render :text => "Error: not saved", :layout => false
    end
  end
  
  def delete_group
    begin
      group = Group.find(params[:id])
      group.destroy
      render :partial => "admin/teams/addressbook/addressbook", :layout => false, :object => @homebase    
    rescue Exception => e
      render :nothing => true, :layout => false 
    end
  end

  def add_address
    begin
      @address = Address.create(params[:add_address]) unless @address = @homebase.addresses.find_by_email(params[:add_address][:email])
      Address.toggle_address_in_group(@address.id, session[:last_group], :add) if session[:last_group]
      render :partial => "admin/teams/addressbook/address_list_item", :object => @address, :layout => false
    rescue Exception => e
      render :nothing => true, :layout => false
    end
  end
  
  def delete_address
    begin
      if request.xhr? or request.post?
        Address.delete(params[:id])
        render :partial => "admin/teams/addressbook/addressbook", :layout => false, :object => Homebase.current_homebase
      end
    rescue Exception => e
      render :nothing => true, :layout => false
    end
  end
  
  def get_group
    if params[:get_all] == "true"
      index
      session[:last_group] = nil
    else
      @group = Group.find(params[:id])
      session[:last_group] = @group.id
    end
    render :partial => "admin/teams/addressbook/address_list", :object => @group, :layout => false
    
  end
  
  def toggle_address_in_group
    if request.xhr? or request.post?
      case params[:checked]
        when "true"
          Address.toggle_address_in_group(params[:address_id], params[:group_id], :add)
        when "false"
          Address.toggle_address_in_group(params[:address_id], params[:group_id], :delete)
      end
    end
    render :nothing => true, :layout => false
  end
  
  def sort_groups
    params[:group_list].each_index do |i|
      item = Group.find(params[:group_list][i])
      item.update_attribute(:position, i)
    end
    render :nothing => true, :layout => false
  end
  
  def sort_addresses
    @order = params[:address_list]
    @order.each_index do |i|
      item = @homebase.addresses.find(@order[i])
      item.update_attribute(:position, i)
    end
    render :nothing => true, :layout => false
  end
  
  
  
  private
  def page_title
    @page_title = "Teams"
  end
  
end
