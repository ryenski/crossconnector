require File.dirname(__FILE__) + '/../test_helper'

class MessageTest < Test::Unit::TestCase
  fixtures :subscription_plans, :homebases, :users, :messages, :comments, :addresses, :groups, :addresses_messages, :addresses_groups, :groups_messages

  def setup
    # Insert the homebase.created_by values
    setup_homebases
  end
  


  
  def test_messages_have_right_number_of_comments
    @message = Message.find(20001)
    @message2 = Message.find(20002)
    
    assert_equal 2, @message.comments.size
    assert_equal 1, @message2.comments.size
  end

  
  
  def test_protect_messages_in_homebase
    assert_can_see_protected_object(users(:ryan),             messages(:private_message), true)
    assert_can_see_protected_object(users(:haiti_leader),     messages(:private_message), true)
    assert_can_see_protected_object(users(:alan),             messages(:private_message), false)
    assert_can_see_protected_object(users(:different_ryan),   messages(:private_message), false)                                                
    assert_can_see_protected_object(users(:haiti_leader),     messages(:haiti_message), true)
    assert_can_see_protected_object(users(:ryan),             messages(:haiti_message), true)
    assert_can_see_protected_object(users(:alan),             messages(:haiti_message), false)
    assert_can_see_protected_object(users(:different_ryan),   messages(:haiti_message), false)
  end                                                
                                                     
  def test_protect_message_marked_as_draft                            
                                                  
    assert_can_see_protected_object(users(:ryan),             messages(:draft_message), true)
    assert_can_see_protected_object(users(:haiti_leader),     messages(:draft_message), false)
    assert_can_see_protected_object(users(:alan),             messages(:draft_message), false)
    assert_can_see_protected_object(users(:haiti_leader),     messages(:draft_message_by_leader), true)
    assert_can_see_protected_object(users(:ryan),             messages(:draft_message_by_leader), false)

  end
  
  def test_find_public_messages
    Homebase.current_homebase = Homebase.find(1)
    @messages = Homebase.current_homebase.public_messages
    assert_equal 16, @messages.size
    
    # Make sure the public-side query doesn't return any private messages
    # This is what the public will see when accessing a public homebase
    for message in @messages
      assert message.private != 1
      assert message.draft != 1
    end
    
    @latest_messages = Homebase.current_homebase.public_messages.find(:all, :limit => 1)
    assert_equal 1, @latest_messages.size
  end
  
  
  # Make sure permalink gets created properly
  # Check to make sure permalinks are unique in the scope of a homebase
  def test_assign_permalinks
    Homebase.current_homebase = Homebase.find(1)
    m1 = Message.create(:subject => "New Message With Permalinks")
    m2 = Message.create(:subject => "New Message With Permalinks")
    m1.reload; m2.reload
    assert_equal "new-message-with-permalinks", m1.permalink
    assert_equal "new-message-with-permalinks-2", m2.permalink
  end
  
  def test_assign_permalinks_in_homebase_scope
    Homebase.current_homebase = Homebase.find(1)
    m1 = Message.create(:subject => "New Message With Permalinks")
    
    Homebase.current_homebase = Homebase.find(2)
    m2 = Message.create(:subject => "New Message With Permalinks")
    
    m1.reload; m2.reload
    
    assert_equal "new-message-with-permalinks", m1.permalink
    assert_equal "new-message-with-permalinks", m2.permalink
  end
  
  def test_assigns_permalink_to_old_messages
    m = Message.find(messages(:haiti_message).id)
    m.save
    assert_equal "message-about-our-haiti-trip", m.permalink
  end
  
  def test_update_permalinks_when_message_updated
    m = Message.find(messages(:haiti_message).id)
    m.subject = "We're going to Disneyland!"
    m.save
    assert_equal "were-going-to-disneyland", m.permalink
  end
  
  def test_specified_permalinks
    Homebase.current_homebase = Homebase.find(1)
    m = Message.create(:subject => "Message with my own permalink", :permalink => "foo-on-you")
    m.save
    assert_equal "message-with-my-own-permalink", m.permalink
  end
  
  def test_prevent_leaders_from_editing_or_deleting_unless_they_have_access
  end
  
  
  # Test that messages was sent to addresses in the addressbook and 
  # that people in the address book can see the mesages that have been sent to them
  def test_message_sent_to_addresses
  end

  
  # Test look up projects associated with message
  # Look up addresses and users from projects associated with message
  
  # Test look up tools for message
  
  
end
