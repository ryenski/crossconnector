require File.dirname(__FILE__) + '/../test_helper'

class ProjectTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :projects, :events, :addresses, :groups, :addresses_projects, :addresses_groups, :groups_projects

  def setup
    setup_homebases
  end
  
  
  def test_received_projects
    Homebase.current_homebase = Homebase.find(2)
    User.current_user = User.find(1003)
    @received_projects = Project.find_received_projects
    assert_not_nil @received_projects
    assert_equal 1, @received_projects.size
    assert_equal projects(:haiti_project).name, @received_projects[0].name
    
    
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = User.find(1001)
    @received_projects = Project.find_received_projects
    assert_not_nil @received_projects
    assert_equal 1, @received_projects.size
    assert_equal projects(:covinavineyard_project_to_haiti).name, @received_projects[0].name
  end
  
  
  def test_create
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = User.find(1001)
    
    @new_project = Project.new
    @new_project.name = "My new project"
    @new_project.save
    @find_new_project = Project.find_by_name("My new project")
    assert_equal 1001, @find_new_project.created_by.id
    assert_equal users(:ryan).email, @find_new_project.created_by.email
  end
  
  def test_create_with_excerpt
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = User.find(1001)
    
    assert project = Project.create(:name => "New Project", :excerpt => "My excerpt", :description => "Foo Project")
    assert_equal "<p>My excerpt</p>", project.excerpt_html
    assert_equal "<p>Foo Project</p>", project.description_html
    
  end
  
  def test_create_private
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = User.find(1001)
    project = Project.new(:name => "Private project", :private_checkbox => 1, :password => "foobar")
    project.save
    assert_not_nil project
    assert_not_nil project.salted_password
    assert_equal "foobar", project.decrypted_password
    assert_equal false, project.new_record?
  end
  
  def test_update_and_clear_private
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = User.find(1001)
    assert project = Project.create(:name => "Private project", :private_checkbox => 1, :password => "foobar")
    
    project.private_checkbox = 0
    project.save
    project.reload
    
    assert_equal 0, project.private
    #assert_equal nil, project.salted_password
    
    
    project2 = Project.create(:name => "Another Private project", :private_checkbox => 1, :password => "foobar")
    project2.update_attribute(:private_checkbox, 0)
    project2.reload
    assert_equal 0, project2.private
    #assert_equal nil, project2.salted_password
    
  end
  
  
  def test_authenticate_project
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = User.find(1001)
    project = Project.new(:name => "Private project 2", :private_checkbox => 1, :password => "foobarss")
    project.save
    assert_equal "foobarss",  project.decrypted_password
    assert project = Project.authenticate(project.permalink, "foobarss")
  end
  
  # A project should have events
  def test_project_has_events
    @project = Project.find(1)
    assert_equal events(:first_event_for_haiti_project), @project.events[0]
    assert_equal 2, @project.events.size
  end
  
  
  def test_update
    Homebase.current_homebase = Homebase.find(1)
    User.current_user = User.find(1001)
    
    @find_project = Project.find(1)
    @find_project.name = "Updated Project"
    @find_project.save
    assert_equal 1001, @find_project.updated_by.id
    assert_equal User.current_user.email, @find_project.updated_by.email
  end
  
  def test_protect_projects_in_homebase
    #Homebase.current_homebase = Homebase.find(1)
    
    assert_can_see_protected_object(users(:ryan),                  projects(:haiti_private_project), true)
    assert_can_see_protected_object(users(:haiti_leader),          projects(:haiti_private_project), true)
    assert_can_see_protected_object(users(:alan),                  projects(:haiti_private_project), false)
    assert_can_see_protected_object(users(:different_ryan),        projects(:haiti_private_project), false)
    
    assert_can_see_protected_object(users(:ryan),                  projects(:haiti_project), true)
    assert_can_see_protected_object(users(:haiti_leader),          projects(:haiti_project), true)
    assert_can_see_protected_object(users(:alan),                  projects(:haiti_project), false)
    assert_can_see_protected_object(users(:different_ryan),        projects(:haiti_project), false)
  end

  def test_prevent_leaders_from_editing_or_deleting_unless_they_have_access
  end
  
  def test_assign_permalinks
    Homebase.current_homebase = Homebase.find(1)
    p = Project.new(:name => "New Project to test permalinks")
    assert_equal true, p.save
    p.reload
    assert_equal "new-project-to-test-permalinks", p.permalink
  end
  
  def test_assign_permalinks_in_homebase_scope
    Homebase.current_homebase = Homebase.find(1)
    p1 = Project.create(:name => "New Project With Permalinks")
    
    Homebase.current_homebase = Homebase.find(2)
    p2 = Project.create(:name => "New Project With Permalinks")
    
    Homebase.current_homebase = Homebase.find(1)
    p3 = Project.create(:name => "New Project With Permalinks")
    
    Homebase.current_homebase = Homebase.find(2)
    p4 = Project.create(:name => "New Project With Permalinks")
    
    p1.reload; p2.reload; p3.reload; p4.reload
    
    assert_equal "new-project-with-permalinks", p1.permalink
    assert_equal "new-project-with-permalinks", p2.permalink
    assert_equal "new-project-with-permalinks-2", p3.permalink
    assert_equal "new-project-with-permalinks-2", p4.permalink
  end
  
  def test_permalinks_with_numbers
    Homebase.current_homebase = Homebase.find(1)
    h1 = Homebase.current_homebase
    p1 = Project.create(:name => "Numbered Project 2343432")
    p2 = Project.create(:name => "Numbered Project 2343432")
    p3 = Project.create(:name => "Numbered Project 2343432")
    
    # By some astronomically random coincidence, someone else 
    # creates three identical projects. 
    Homebase.current_homebase = Homebase.find(2)
    h2 = Homebase.current_homebase
    p4 = Project.create(:name => "Numbered Project 2343432")
    p5 = Project.create(:name => "Numbered Project 2343432")
    p6 = Project.create(:name => "Numbered Project 2343432")
    
    assert_equal "numbered-project-2343432", p1.permalink
    assert_equal "numbered-project-2343432-2", p2.permalink
    assert_equal "numbered-project-2343432-3", p3.permalink
    assert_equal h1.id, p1.homebase.id
    assert_equal h1.id, p2.homebase.id
    assert_equal h1.id, p3.homebase.id

    assert_equal "numbered-project-2343432", p4.permalink
    assert_equal "numbered-project-2343432-2", p5.permalink
    assert_equal "numbered-project-2343432-3", p6.permalink
    assert_equal h2.id, p4.homebase.id
    assert_equal h2.id, p5.homebase.id
    assert_equal h2.id, p6.homebase.id
    
  end

  # Test look up project by address
  # Test look up project by group
  
  # Look up messages for this project
  
  # Look up files for this project
  
end
