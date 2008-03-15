module Admin::FileHelper
  
  def filename_link_for(file)
    link_to(label_for(file), :controller => "/public", :action => "file", :permalink => file.permalink)
  end
  
  def filename_permalink_for(file)
    link_to(label_for(file), :controller => "/public", :action => "file", :permalink => file.permalink)
  end
  
  def label_for(file)
    file.name.blank? ? file[:file] : h(file.name)
  end
  
  def html_for_image(image)
    link = "<a href=\"http://#{Homebase.current_homebase.subdomain}.#{App::CONFIG[:app_domain]}/file/#{image[:permalink]}\">"
    link << "<img src=\"http://files.#{Homebase.current_homebase.subdomain}.#{App::CONFIG[:app_domain]}/images/#{image[:id]}/screen/#{image[:file]}\" class=\"border\" />"
    link << "</a>"
  end
  
  def html_for_file(file)
    "<a href=\"http://#{Homebase.current_homebase.subdomain}.#{App::CONFIG[:app_domain]}/file/#{file[:permalink]}\">#{file[:file]} (#{human_size(file[:size])} #{long_file_type(file)})</a>"
  end
  
  
  def short_file_type(file)
    type = file.content_type
    case type
    when "application/pdf"
      "acrobat"
    when "image/jpeg", "image/gif", "image/png"
      "paint"
    when "application/msword"
      "msword"
    when "application/vnd.ms-excel"
      "msexcel"
    when "video/mpeg", "video/quicktime", "video/quicktime", "video/x-msvideo", "video/x-ms-asf", "video/x-ms-asf", "video/x-ms-wmv"
      "video"
    when "audio/mpeg"
      "audio"
    when "application/x-shockwave-flash"
      "flash"
    else
      "generic" 
    end
  end
  
  def long_file_type(file)
    type = file.content_type
    case type
    when "application/pdf"
      "Adobe Acrobat document"
    when "image/jpeg"
      "JPG image"
    when "image/gif"
      "GIF image"
    when "image/png"
      "PNG image"
    when "application/msword"
      "Microsoft Word document"
    when "application/vnd.ms-excel"
      "Microsoft Excel document"
    when "application/x-shockwave-flash"
      "Macromedia Flash file"
    when "audio/mpeg"
      "MP3 file"
    when "application/zip", "application/x-tgz", "application/x-tar", "application/x-bzip", "application/x-bzip-compressed-tar"
      "Compressed archive file"
    when "text/plain"
      "Text file"
    when "video/mpeg"
      "MPEG video"
    when "video/quicktime"
      "Quicktime video"
    else
      "File"
    end
  end
    
  
end
