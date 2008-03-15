require 'test/unit'
require File.dirname(__FILE__) + '/../../lib/active_merchant'

class MoenrisRemoteTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
  
  def setup
    @gateway = MonerisGateway.new({
        :login => 'store1',
        :password => 'yesguy',
      })

    @creditcard = CreditCard.new({
      :number => '4242424242424242',
      :month => 8,
      :year => 2006,
      :name => 'Longbob Longsen',
    })
  end
  
  def test_remote_purchase
    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard, :order_id => "moneris_testcase_" + rand.to_s)
    assert_equal Response, response.class
    assert_equal     ["authcode",
     "banktotals",
     "cardtype",
     "complete",
     "iso",
     "message",
     "receiptid",
     "referencenum",
     "responsecode",
     "ticket",
     "timedout",
     "transamount",
     "transdate",
     "transid",
     "transtime",
     "transtype"], response.params.keys.sort
    assert_match /APPROVED/, response.params['message']
    assert_equal 'Approved', response.message
    assert_equal true, response.params['complete']
    assert_equal true, response.success?
  end

  def test_remote_error
    assert response = @gateway.purchase(Money.ca_dollar(150), @creditcard, :order_id => "moneris_testcase_" + rand.to_s)
    assert_equal Response, response.class
    assert_equal ["authcode",
     "banktotals",
     "cardtype",
     "complete",
     "iso",
     "message",
     "receiptid",
     "referencenum",
     "responsecode",
     "ticket",
     "timedout",
     "transamount",
     "transdate",
     "transid",
     "transtime",
     "transtype"], response.params.keys.sort
    assert_match /DECLINED/, response.params['message']
    assert_equal 'Declined', response.message
    assert_equal true, response.params['complete']
    assert_equal false, response.success?
  end
    
end