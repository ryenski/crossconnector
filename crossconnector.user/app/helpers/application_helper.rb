# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def page_title
    t = @homebase.name || "Homebase"
    t << " - #{@page_title}" if @page_title
    return t
  end
  
  def link_to_rss(text, feed_type)
    link_to text, :controller => "feed", :action => "rss", :type => feed_type
  end
  
  # Redefines the auto_link_email_addresses from 
  #   vendor/rails/actionpack/lib/action_view/helpers/text_helper.rb
  # Turns all email addresses into clickable links.  If a block is given,
  # each email is yielded and the result is used as the link text.
  # Example:
  #   auto_link_email_addresses(post.body) do |text|
  #     truncate(text, 15)
  #   end
  def auto_link_email_addresses(text)
    text.gsub(/([\w\.!#\$%\-+.]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+)/) do
      text = $1
      text = yield(text) if block_given?
      mail_to $1, text, :encode => "javascript"
    end
  end

  
  def logo
    content_tag("div", image_tag("http://files.#{@homebase.subdomain}.#{App::CONFIG[:app_domain]}/logo/#{@homebase.id}/#{@homebase["logo"]}")) if logo?
  end
  
  def logo?
    return false if @homebase["logo"].nil?
    return true
  end
  
  def admin_tools_for(model,parent_model=nil)
    parent_model ||= model
    return nil if !user_can_edit? parent_model.class
    return nil if @request.parameters[:controller] == "public"
    type = model.class.name.to_s.downcase
    path = case type 
      when "event" then "plan"
      when "comment" then "blog"
    end
    tag = []
    tag << content_tag("div", 
      image_tag("/images/spinner.gif", :id => "#{type}_form_#{model.id}_indicator", :style => "display:none;") <<
      
      link_to_remote(content_tag("span", "edit", :class => "#{type}_editicon"),
        :url => {:controller => "#{type}", :action => "open_#{type}_form", :state => "edit", :id => model.id},
        :update => "#{type}_edit_form_#{model.id}",
        :loading => "Element.show('#{type}_form_#{model.id}_indicator')",
        :complete => "Element.show('#{type}_edit_form_#{model.id}'); Element.hide('#{type}_body_#{model.id}'); Element.hide('#{type}_form_#{model.id}_indicator')") <<
      " | " <<
      link_to_remote(content_tag("span", "delete", :class => "#{type}_deleteicon"), 
        :url => {:controller => "#{type}", :action => "delete", :id => model.id}, 
        :confirm => "Are you sure you want to delete this #{type}?", 
        :loading => "Element.show('#{type}_form_#{model.id}_indicator')",
        :complete => "new Effect.Fade('#{type}_list_item_#{model.id}'), {duration:0.5}"),
      
      :class => "admin_tools")
  end
  
  
  
  def user_can_edit?(type)
    return false if User.current_user.nil?
    return true if User.class == User
    return true if User.current_user == Homebase.current_homebase.created_by
    return true if User.find_first(["id = ? AND can_edit_#{type.to_s}s = 1", User.current_user.id])
    return false
  end
  
  def user?
    !@session[:user].nil?
  end
  
  def expandable(element_name,default_state=nil)
    link_to_function("#{image_tag("/images/icons/arrow-right.gif")} #{element_name.capitalize}", "new Effect.BlindDown('#{element_name}', {duration:0.1}),Element.toggle('#{element_name}-arrow-down'),Element.toggle('#{element_name}-arrow-right')", :id => "#{element_name}-arrow-right", :style => default_state)
  end

  # Outputs a list item with the requested navigation item. 
  # Sets the class to "current" if the argument matches current_section
  def navigation_link(nav,text=nil)
    text ||= nav
    "<li id=\"#{nav.split("/").last.downcase}_tab\">#{link_to(text, :controller => "/#{nav.downcase}")}</li>"
  end
  
  def page_title_icon(icon=current_section)
    image_tag("/images/icons/helsinki_gif/#{icon}.gif")
  end

  # Current_section does a regex match on the request_uri and returns the first string of characters only. 
  # Used for highlighting the current tab in the navigation menu
  def current_section
  	current_controller.split("/").last
  end
  
  def current_controller
    controller.request.path_parameters['controller']
  end
    
  def current_subsection
  	re = (/[a-z]+$/)
  	re.match(current_controller).to_s
  end


  # Print the title of the current section, complete with CSS class details. 
  def current_section_title
  	"<h1 class=\"#{current_section} sectiontitle\">#{current_section.capitalize}</h1>"
  end
  
  # Converts a boolean value to Yes or No. 
  def yes_no(bool)
    case bool
    when 1
      "yes"
    when 0
      "no"
    end
  end
  
  def pluralize_with_verb(count,noun,verb=nil)
    pluralize(count, noun) if verb.nil?
    case count
      when 1: "#{count} #{noun} #{verb}s"
      else    "#{pluralize(count, noun)} #{verb}"
    end
  end

   
  # This could be localized... 
  def localized_date(date)
    date.strftime("%b %d, %Y")
  end
  
  def localized_short_date(date)
    date.strftime("%d %b")
  end
  

  def link_to_user_name(user,truncate=nil)
    if user? and (user.id == session[:user].id)
      return "<strong>#{truncate(user.name,truncate)} (you)</strong>" if !truncate.nil?
      return "<strong>you</strong>"
    else
      user.name = truncate(user.name,truncate) if !truncate.nil?
      return link_to("#{user.name}", "http://#{user.homebase.subdomain}.#{@request.domain}")
    end
  end
  
  def link_to_received(object)
    type = object.class.name.to_s.downcase
    case type
    when "message"
      text = object.subject
    when "project", "file"
      text = object.name
    end
    link_to( truncate(h(text),20), "http://#{object.homebase.subdomain}.#{@request.domain}/#{type}/#{object.id}", :class => "#{type}_link icon")
  end
  
  def address_exists?(address)
    return true if User.find_by_email(address)
    #return true if Homebase.find_by_sql(["select id from homebases where id IN (select email from Users where email = ? and Users.type != 'Editor' and Users.type != 'Admin' limit 1) limit 1", address])
    return false
  end
  
  
  # Email link - only displays a link if the user is authenticated. Otherwise chooses between the name or email plain text. 
  def email_link_to(obj)
    link_to("#{obj.name? ? h(obj.name) : h(obj.email)}", "mailto:#{h(obj.email)}")
  end
  
  #def link_to_user_organization(user)
  #  text = user.organization 
  #  text = user.name if user.organization.empty?
  #  link_to(text, "http://#{user.homebase}.#{@request.domain}")
  #end
  
  
  # Infers the link to the corresponding public page
  def link_to_public(text="View your public site")
    begin
      l = (/\/admin\/(messages|message|projects|project|files)(\/*[\w\d-]*)/).match(request.env["REQUEST_URI"])
      l = "#{l[1]}#{l[2]}"
      l = l.gsub("/new", "s")
      link_to(text, "/#{l}", :class => "link icon dark")
    rescue 
      link_to(text, "/", :class => "link icon dark")
    end
  end
  
  def link_to_homebase(homebase=Homebase.current_homebase, text=nil)
    text ||= "#{homebase.subdomain}.#{App::CONFIG[:app_domain]}"
    link_to(text, "http://#{homebase.subdomain}.#{App::CONFIG[:app_domain]}")
  end
  
  def url_for_homebase(homebase=Homebase.current_homebase)
    url_for("http://#{homebase.subdomain}.#{App::CONFIG[:app_domain]}")
  end
  
  def link_to_project(project)
    link_to(truncate(project.name, 20), "http://#{project.homebase.subdomain}.#{App::CONFIG[:app_domain]}/project/#{project.id}")
  end
  
  def link_to_my_blog(link_text)
    link_to(link_text, "http://#{Homebase.current_homebase.subdomain}.#{App::CONFIG[:app_domain]}/")
  end
  
  def support_contact(link_text="support")
    link_to link_text, "mailto:ryan@artofmission.com"
  end
  
  def protected_link_to_control(name, options={}, html_options=nil, *parameters_for_method_reference)
    content_tag("li", protected_link_to(name, options, html_options, *parameters_for_method_reference), :class => "control_button")
  end
  
  def protected_link_to(name, options={}, html_options=nil, *parameters_for_method_reference)
    if user_can_edit? options[:controller].split("/").last
      link_to(name, options, html_options, *parameters_for_method_reference)
    end
  end
  
  def link_to_project(project)
    link_to(project.name, :controller => "/admin/project", :action => "show", :permalink => project.permalink)
  end
  
  #
  # deprecated
  def button_for(action,type,id=nil)
    if user_can_edit? type
      case action
      when "new"
        link_to("DEPRECATED New #{type}", {:action => "new"}, :class => "#{type}_add icon")
      when "edit"
        link_to("DEPRECATED Edit this #{type}", {:action => :edit, :id => id}, :class => "#{type}_edit icon")
      end
    end
  end
  
  def you?(person)
    return true if person.id == session[:user].id
    return false
  end
  
  def current_action
    params[:action].to_s.downcase
  end

  
  # Storage is privelege id=2
  def within_storage_limit?
    #return true if @homebase.plan.priveleges.find(2).plan_limit.to_i == 0
    #return true if @homebase.total_files.to_f/1024.kilobytes <= @homebase.plan.priveleges.find(2).plan_limit.to_i
    return true if @homebase.within_storage_limit?
    return false
  end
  
  # Projects is privelege id=1
  def within_projects_limit?
    #return true if @homebase.plan.priveleges.find(1).plan_limit.to_i == 0
    #return true if @homebase.projects.count < @homebase.plan.priveleges.find(1).plan_limit.to_i
    return true if @homebase.within_projects_limit?
    false
  end
  
  def email_support_link
    "<a href=\"mailto:#{App::CONFIG[:admin_email]}\">#{App::CONFIG[:admin_email]}</a>"
  end
  
  def url_for_blog_item(item)
    type = item.class.name.to_s.downcase
    "http://#{Homebase.current_homebase.subdomain}.#{App::CONFIG[:app_domain]}/#{type}/#{item.permalink}"
  end
  
  def commify(number)
    c = { :value => "", :length => 0 }
    r = number.to_s.reverse.split("").inject(c) do |t, e|  
      iv, il = t[:value], t[:length]
      iv += ',' if il % 3 == 0 && il != 0    
      { :value => iv + e, :length => il + 1 }
    end
    r[:value].reverse!
  end
  
  def file_size_examples(size)
    [
     "#{commify(size)} full-size photos",
     "#{commify(size)} minutes of MP3 music",
     "#{commify(size)} books (without pictures)",
     "#{commify(size.to_i * 10)} small images",
     "#{commify(n = (size / 60).to_i)} one-hour sermon podcast#{"s" if n > 1}"
     ]
  end

end



