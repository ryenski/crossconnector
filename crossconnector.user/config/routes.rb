ActionController::Routing::Routes.draw do |map|

  map.connect '', :controller => 'public', :action => 'homebase'

  # Admin
  map.connect '/admin', :controller => 'admin/homebase', :action => 'index'
  map.connect '/admin/projects', :controller => 'admin/project'
  map.connect '/admin/messages', :controller => 'admin/message'
  map.connect '/admin/files', :controller => 'admin/file'
  map.connect '/admin/teams/leaders', :controller => 'admin/teams/leader'
  map.connect '/admin/teams/leader/:action/:id', :controller => 'admin/teams/leader'
  map.connect '/admin/login', :controller => 'admin/account', :action => 'login'
  
  # Transcendent actions
  map.connect '/:controller/new', :action => 'new'
  
  # Pagination
  map.connect '/admin/projects/page/:page',         :controller => 'admin/project', :action => 'index'
  map.connect '/admin/messages/page/:page',         :controller => 'admin/message', :action => 'index'
  map.connect '/admin/files/page/:page',            :controller => 'admin/file', :action => 'index'
  
  # Permalinks
  map.connect '/admin/project/:permalink',          :controller => 'admin/project', :action => 'show'
  map.connect '/admin/project/:permalink/:action',  :controller => 'admin/project'

  map.connect '/admin/message/:permalink',          :controller => 'admin/message', :action => 'show'
  map.connect '/admin/message/:permalink/:action',  :controller => 'admin/message'

  map.connect '/admin/file/:permalink',             :controller => 'admin/file', :action => 'download'
  map.connect '/admin/file/:permalink/:action',     :controller => 'admin/file'
  
  
  # Public
  map.connect '/about',                             :controller => 'public', :action => 'about'
  
  map.connect '/messages',                          :controller => 'public', :action => 'messages'
  map.connect '/message/:permalink',                :controller => 'public', :action => 'message'
  map.connect '/messages/page/:page',               :controller => 'public', :action => 'messages'
  map.connect '/messages/:tag',                     :controller => 'public', :action => 'messages'
  map.connect '/messages/:tag/page/:page',          :controller => 'public', :action => 'messages'
                                            
  map.connect '/projects',                          :controller => 'public', :action => 'projects'
  map.connect '/project/:permalink',                :controller => 'public', :action => 'project'
  map.connect '/projects/page/:page',               :controller => 'public', :action => 'projects'
  map.connect '/projects/:tag',                     :controller => 'public', :action => 'projects'
  map.connect '/projects/:tag/page/:page',          :controller => 'public', :action => 'projects'
                                            
  map.connect '/files',                             :controller => 'public', :action => 'files'
  map.connect '/file/:permalink',                   :controller => 'public', :action => 'file'
  map.connect '/file/:permalink/:size',             :controller => 'public', :action => 'file'
  map.connect '/files/page/:page',                  :controller => 'public', :action => 'files'
  map.connect '/files/:tag',                        :controller => 'public', :action => 'files'
  map.connect '/files/:tag/page/:page',             :controller => 'public', :action => 'files'
  
  # Public Login
  map.connect '/public/login/:object/:permalink', :controller => 'public', :action => 'login'
  
  map.connect '/login', :controller => 'admin/account', :action => 'login'
  
  #map.connect '/page/:name', :controller => 'page', :action => 'show'
  
  # RSS Feeds
  map.connect '/feed/:action/:type', :controller => 'feed'
  
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'
  
  # Theme stuff
  map.stylesheets "/stylesheets/theme/:filename",
    :controller => 'theme', :action => 'stylesheets', :requirements => {:filename => /\w+\.css/}
  map.connect 'javascript/theme/:filename',
    :controller => 'theme', :action => 'javascript', :requirements => {:filename => /\w+\.js/}
  map.connect 'images/theme/:filename',
    :controller => 'theme', :action => 'images', :requirements => {:filename => /\w+\.(png|gif|jpg)/}

  # Kill attempts to connect directly to the theme controller.
  map.connect 'theme/*stuff',
    :controller => 'theme', :action => 'error'
    
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  
  map.connect '*anything', :controller => "public", :action => "render_404"
end
