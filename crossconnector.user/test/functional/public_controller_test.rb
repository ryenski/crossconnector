require File.dirname(__FILE__) + '/../test_helper'
require 'public_controller'

# Re-raise errors caught by the controller.
class PublicController; def rescue_action(e) raise e end; end

class PublicControllerTest < Test::Unit::TestCase
  
  fixtures :subscription_plans, :homebases, :users, :projects, :messages, :resources, :tags, :tags_messages,  :tags_resources, :tags_projects
  
  def setup
    
    @controller = PublicController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    setup_homebases
    
    # We're running these tests in the first homebase
    #Homebase.current_homebase = Homebase.find(1)
    @homebase = Homebase.current_homebase
    # Clear the session, just in case
    
  end

  
  def test_list_projects
    get :projects
    assert_response :success
    assert_equal 3, assigns(:homebase).public_projects.size
    assert_equal 1, assigns(:homebase).archived_projects.size
  end
  
  def test_show_project
    before = Project.find(projects(:haiti_project).id)
    
    get :project, :permalink => projects(:haiti_project).permalink
    assert_response :success
    assert_not_nil assigns(:project)
    assert_equal projects(:haiti_project), assigns(:project)
    p = Project.find(assigns(:project).id)
    assert_equal before.access_logs.size + 1, p.access_logs.size
    
  end
  
  def test_show_nonexistant_project
    get :project, :permalink => "notaproject"
    assert_response :redirect
    assert_redirected_to "/projects"
    assert_not_nil flash[:notice]
    
  end
  
  def test_hide_private_project
    get :project, :permalink => projects(:haiti_private_project).permalink
    assert_response :success
    assert_template "_login"
  end
  
  def test_hide_project_from_wrong_homebase
    get :project, :permalink => projects(:covinavineyard_project_to_haiti).permalink
    assert_response :redirect
  end
  
  def test_list_messages
    get :messages
    assert_response :success
    assert_equal 16, assigns(:homebase).public_messages.size
  end
  
  def test_show_message
    Homebase.current_homebase = Homebase.find(1)
    before = Message.find( messages(:haiti_message).id)
        
    get :message, :permalink => messages(:haiti_message).permalink
    
    assert_response :success
    assert_equal messages(:haiti_message), assigns(:message)
    
    m = Message.find(assigns(:message).id)
    assert_equal before.access_logs.size + 1, m.access_logs.size
  end
  
  #def test_hide_private_message
  #  get :message, :permalink => messages(:private_message).permalink
  #  assert_response :success
  #  #breakpoint
  #  assert_template "_login"
  #  
  #  get :message, :permalink => messages(:draft_message).permalink
  #  assert_response :redirect
  #end
  
  def test_tagged_projects
    get :projects, :tag => "haiti"
    assert_response :success
    
    assert_equal 2, assigns(:related_tags).size
    assert_equal 1, assigns(:projects).size
  end
  
  def test_tagged_messages
    get :messages, :tag => "haiti"
    assert_response :success
    
    assert_equal 1, assigns(:related_tags).size
    assert_equal 1, assigns(:messages).size
  end
  
  
  def test_tagged_files
    get :files, :tag => "haiti"
    assert_response :success
    
    assert_equal 1, assigns(:related_tags).size
    assert_equal 1, assigns(:files).size
    
  end
  
  def test_routing_for_message
    opts = {:controller => "public", :action => "message", :permalink => "foo"}
    assert_routing("message/foo", opts)
    
    #opts = {:controller => "public", :action => "message", :permalink => "page"}
    #assert_routing("message/page", opts)
    
    get :message, :permalink => "page"
    assert_response :success
    assert_equal messages(:message_that_might_screw_up_routing).subject, assigns(:message).subject
  end
  
  def test_routing_for_messages
    opts = {:controller => "public", :action => "messages"}
    assert_routing("messages", opts)
    
    opts = {:controller => "public", :action => "messages", :page => "2"}
    assert_routing("messages/page/2", opts)
  end
  
  def test_routing_for_messages_with_tag
    opts = {:controller => "public", :action => "messages", :tag => "foo", :page => "2"}
    assert_routing("messages/foo/page/2", opts)
  end
  
  
  
  
  def test_routing_for_project
    opts = {:controller => "public", :action => "project", :permalink => "foo"}
    assert_routing("project/foo", opts)

    #opts = {:controller => "public", :action => "project", :permalink => "page"}
    #assert_routing("project/page", opts)

    get :project, :permalink => projects(:haiti_project).permalink
    assert_response :success
    assert_equal projects(:haiti_project).name, assigns(:project).name
    
    get :project, :permalink => projects(:project_that_might_screw_up_routing).permalink
    assert_response :success
    assert_equal projects(:project_that_might_screw_up_routing).name, assigns(:project).name
  end

  def test_routing_for_projects
    opts = {:controller => "public", :action => "projects"}
    assert_routing("projects", opts)

    opts = {:controller => "public", :action => "projects", :page => "2"}
    assert_routing("projects/page/2", opts)
  end

  def test_routing_for_projects_with_tag
    opts = {:controller => "public", :action => "projects", :tag => "foo", :page => "2"}
    assert_routing("projects/foo/page/2", opts)
  end
  
  
  
  def test_routing_for_file
    opts = {:controller => "public", :action => "file", :permalink => "foo"}
    assert_routing("file/foo", opts)

  end

  def test_routing_for_files
    opts = {:controller => "public", :action => "files"}
    assert_routing("files", opts)

    opts = {:controller => "public", :action => "files", :page => "2"}
    assert_routing("files/page/2", opts)
  end

  def test_routing_for_files_with_tag
    opts = {:controller => "public", :action => "files", :tag => "foo", :page => "2"}
    assert_routing("files/foo/page/2", opts)
  end
  
  
  def test_paginated_messages
    
  end
  
  #def test_protect_messages_in_private_project
  #  assert_equal true, messages(:message_in_private_project).private?
  #  assert_equal 0, messages(:message_in_private_project).private
  #  get :message, :permalink => messages(:message_in_private_project)
  #  assert_redirected_to :action => :messages
  #end
  
end
