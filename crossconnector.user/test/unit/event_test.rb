require File.dirname(__FILE__) + '/../test_helper'

class EventTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :projects, :events

  def setup
    
    setup_homebases
    
    @event = Event.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Event,  @event
  end
  
  # Most of the good event-related tests are in project_test.rb
  
  def test_set_first_event
    
    project = Project.find(1)
    assert_nil project.first_event
    
    start_date = 5.days.from_now
    event = Event.new(:project_id => 1, :name => "New First Event", :start_date => start_date)
    event.save
    
    project = Project.find(1)
    assert_equal start_date.to_s, project.first_event.to_s
    
  end
  
  def test_set_first_event_on_delete
    event = Event.find(events(:first_event_for_haiti_project).id)
    event.destroy
    project = Project.find(1)
    assert_equal events(:second_event_for_haiti_project).start_date.to_s, project.first_event.to_s
  end
  
  def test_increment_event_counter
    project = projects(:haiti_project)
    assert_equal 2, project.events.count
    Event.create(:project_id => project.id, :name => "new event", :start_date => Time.now + 1.week)
    project.reload
    assert_equal 3, project.events.count
    project = Project.find(projects(:haiti_project).id)
    assert_equal 3, project.events.count
  end
  
  def test_deincrement_event_counter
    project = projects(:haiti_project)
    assert_equal 2, project.events.count
    Event.find(project.events[0].id).destroy
    assert_equal 1, project.events.count
    
    #Just to make sure...
    project = Project.find(projects(:haiti_project).id)
    assert_equal 1, project.events.count
  end
  
  
  
  
end
