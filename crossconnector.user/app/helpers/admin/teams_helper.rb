module Admin::TeamsHelper
    
  def list_of_addresses_with_homebase(user=User.current_user)
    list = User.find_by_sql ["select * from users where users.email in (select email from addresses where created_by = ? and id != ?)", user.id, user.id]
  end
  
  # Overrides the default admin_tools_for in application_helper.rb
  def addressbook_admin_tools_for(model)
    return nil if !user_can_edit? model
    type = model.class.name.to_s.downcase
    tag = content_tag("span", 
      form_remote_tag(:url => {:controller => "teams", :action => "delete_#{type}", :id => model.id},
                      :loading => "new Effect.Fade('#{type}_list_item_#{model.id}', {duration:0.2})",
                      :update => "update_status",
                      :confirm => "Are you sure you want to delete this #{type}?") <<
      link_to_function(image_tag("../images/icons/silk/pencil.png"), "Element.show('#{type}_list_item_#{model.id}_form'), Element.hide('#{type}_list_item_#{model.id}_content')") <<
      image_submit_tag("../images/icons/silk/delete.png") <<
      end_form_tag,
      :id => "admin_tools_for_#{type}_#{model.id}",
      :class => "admin_tools_for_addressbook",
      :style => "display:none;")    
  end
  
  def mailing_address_for?(user = @homebase)
    return true if user.address1 or user.address2 or user.city or user.state or user.postal or user.country
    return false
  end
  
  def mailing_address_for(user)
    r = ""
    r << "#{user.address1}<br />" if !user.address1.nil? and !user.address1.empty?
    r << "#{user.address2}<br />" if !user.address2.nil? and !user.address2.empty?
    r << "#{user.city}," if !user.city.nil? and !user.city.empty?
    r << " #{user.state}" if !user.state.nil? and !user.state.empty?
    r << " #{user.postal}<br />" if  !user.postal.nil? and !user.postal.empty?
    r << " #{user.country}" if !user.country.nil? and !user.country.empty?
    return nil if r == ""
    return r
  end
  
  
  # Output the little "edit field" buttons in the address_detail section
  def quick_update_form(label,obj,field_name=nil)
    field_name = label.to_s.downcase if field_name.nil?
    tag = 
      content_tag("span", link_to_function("edit", "Element.toggle('address_detail_#{field_name}'), Element.toggle('address_detail_#{field_name}_form')") << 
        " #{obj[field_name].nil? || obj[field_name] == "" ? content_tag("span", h(label), :class => "faded"): h(obj[field_name].to_s)}", 
        :class => "nowrap", 
        :id => "address_detail_#{field_name}") <<
      
      content_tag("span", 
        form_remote_tag(:url => {:action => "update_address"},
                        :update => "addressbook_detail",
                        :loading => "Element.show('update_#{field_name}_indicator')") <<
        
          text_field("address", field_name, :value => h(obj[field_name].to_s))  << 
          hidden_field("address", "id", :value => h(obj["id"]))  << "<br />" <<
          image_tag("/images/spinner.gif", :id => "update_#{field_name}_indicator", :style => "display:none;") <<
          submit_tag("Save #{label.downcase}") << " or " <<
          link_to_function("Cancel", "Element.toggle('address_detail_#{field_name}'), Element.toggle('address_detail_#{field_name}_form')") <<
        end_form_tag,
        :id => "address_detail_#{field_name}_form", :style => "display:none")
          
  end


end



