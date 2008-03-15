module Admin::AccountHelper
  
  def user_site_name
    r = "<h2>#{@user.organization}</h2><h3>#{@user.name}</h3>" if !@user.organization.nil? and @user.organization != ""
    r ||= "<h2>#{@user.name}</h2>"
    r << "#{@user.tagline}"
    
  end
  
  def can_downgrade?(homebase,plan)
    homebase.projects.count <= plan.priveleges.find(1).plan_limit.to_i and (homebase.total_files / 1.megabyte).to_i <= plan.priveleges.find(2).plan_limit.to_i
  end
  
  def up_or_downgrade_link(homebase,plan)
    return link_to("upgrade", {:controller => "account", :action => "subscription", :plan => plan.name}) if plan.price > homebase.subscription.plan.price
    return link_to("downgrade", {:controller => "account", :action => "subscription", :plan => plan.name}) if can_downgrade?(homebase,plan)
    return nil
    return "downgrade*"
  end

  
  def upgrade_link(subscription, plan)
    if subscription.plan.id == plan.id 
      subscription.trial? ? link_to("pay now", :controller => "account", :action => "subscription", :plan => plan.name) : "your plan"
    else
      up_or_downgrade_link(subscription.homebase, plan)
    end
  end
  
end
  
