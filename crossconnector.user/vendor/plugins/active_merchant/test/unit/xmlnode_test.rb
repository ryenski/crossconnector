require File.dirname(__FILE__) + '/../test_helper'

class XmlNodeTest < Test::Unit::TestCase
  def test_all
    xn = XmlNode.from_xml(fixture)     
    assert_equal 'UTF-8', xn.node.document.encoding
    assert_equal '1.0', xn.node.document.version
    assert_equal 'true', xn.response['success']
    assert_equal 'Ajax Summit', xn.response.page['title']
    assert_equal '1133', xn.response.page['id']
    assert_equal "With O'Reilly and Adaptive Path", xn.response.page.description.value
    assert_equal nil, xn.nonexistent
    assert_equal "Staying at the Savoy", xn.response.page.notes.note.value.strip
    assert_equal 'Technology', xn.response.page.tags.tag[0]['name']
    assert_equal 'Travel', xn.response.page.tags.tag[1][:name]
    matches = xn.xpath('//@id').map{ |id| id.to_i }
    assert_equal [4, 5, 1020, 1133], matches.sort
    matches = xn.xpath('//tag').map{ |tag| tag['name'] }
    assert_equal ['Technology', 'Travel'], matches.sort
    assert_equal "Ajax Summit", xn.response.page['title']
    xn.response.page['title'] = 'Ajax Summit V2'
    assert_equal "Ajax Summit V2", xn.response.page['title']
    assert_equal "Staying at the Savoy", xn.response.page.notes.note.value.strip
    xn.response.page.notes.note.value = "Staying at the Ritz"
    assert_equal "Staying at the Ritz", xn.response.page.notes.note.value.strip
    assert_equal '5', xn.response.page.tags.tag[1][:id]
    xn.response.page.tags.tag[1]['id'] = '7'
    assert_equal '7', xn.response.page.tags.tag[1]['id']
  end
  
  def fixture
    %{<?xml version="1.0" encoding="UTF-8"?>
      <response success='true'>
      <page title='Ajax Summit' id='1133' email_address='ry87ib@backpackit.com'>
        <description>With O'Reilly and Adaptive Path</description>
        <notes>
          <note title='Hotel' id='1020' created_at='2005-05-14 16:41:11'>
            Staying at the Savoy
          </note>
        </notes>
        <tags>
          <tag name='Technology' id='4' />
          <tag name='Travel' id='5' />
        </tags>
      </page>
      </response>
     }
  end
end
