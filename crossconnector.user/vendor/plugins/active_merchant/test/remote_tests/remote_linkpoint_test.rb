#
# In order for this test to pass, a valid store number and PEM file 
# are required. Unfortunately, with LinkPoint YOU CAN'T JUST USE ANY 
# OLD STORE NUMBER. Also, you can't just generate your own PEM file. 
# You'll need to use a special PEM file provided by LinkPoint. 
#
# Go to http://www.linkpoint.com/support/sup_teststore.asp to set up 
# a test account and obtain your PEM file. 
#

require 'test/unit'
require File.dirname(__FILE__) + '/../test_helper'

ActiveMerchant::Billing::LinkpointGateway.pem_file = File.read( File.dirname(__FILE__) + '/../1909173667.pem'  )
ActiveMerchant::Billing::LinkpointGateway.gateway_mode = :staging  


class LinkpointTest < Test::Unit::TestCase
  include ActiveMerchant::Billing

  def setup
    @gateway = LinkpointGateway.new(:store_number => "1909173667", :result => "LIVE")

    @creditcard = CreditCard.new({
      :number => '4111111111111111',
      :month => Time.now.month.to_s,
      :year => (Time.now + 1.year).year.to_s[2,3],
      :name => 'Captain Jacks',
      :address1 => '1313 lucky lanes',
      :city => 'Lost Angeles',
      :state => 'CA',
      :zip => '90211'
    })
  end
  
  def test_remote_authorize
    assert_equal File.read( File.dirname(__FILE__) + '/../1909173667.pem'), @gateway.pem_file
    assert_equal :staging, @gateway.gateway_mode
    assert_equal "1909173667", @gateway.options[:store_number]
    
    assert response = @gateway.authorize(Money.us_dollar(2400), @creditcard, :order_id => 1000)
    assert_equal Response, response.class
    #assert_equal "foo", response
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  def test_remote_capture
    assert response = @gateway.capture(Money.us_dollar(2400), @creditcard, :order_id => 1000)
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  def test_remote_purchase
    assert response = @gateway.purchase(Money.us_dollar(2400), @creditcard, :order_id => 1001)
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  def test_remote_credit
    assert response = @gateway.credit(Money.us_dollar(2400), @creditcard, :order_id => 1001)
    assert_equal Response, response.class
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end

  
  def test_remote_recurring
    assert response = @gateway.recurring(Money.us_dollar(2400), @creditcard, :order_id => 1006, :installments => 12, :startdate => Time.now.next_month.strftime("%Y%m%d"), :periodicity => :monthly)
    assert_equal Response, response.class
    assert_equal "foo", response
    assert_equal true, response.success?
    assert_equal "APPROVED", response.params["r_approved"]
  end
  
  
  def test_remote_decline
    @gateway = LinkpointGateway.new(:store_number => 1909173667, :result => "DECLINE")
    assert response = @gateway.purchase(Money.us_dollar(100), @creditcard, :order_id => 1002)
    assert_equal Response, response.class
    assert_equal false, response.success?
    assert_equal "DECLINED", response.params["r_approved"]
  end
end