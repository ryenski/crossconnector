module FeedHelper
  def pub_date(date)
    date.rfc822
  end
  
  def post_link(item)
    url_for :controller => "public", :action => item.class.name.to_s.downcase, :permalink => item.permalink
  end
  
  def file_label(item)
    item.name.blank? ? item[:file] : h(item.name)
  end
  
  def file_link(item)
    url_for :controller => "public", :action => "file", :permalink => item.permalink
  end
  
end
