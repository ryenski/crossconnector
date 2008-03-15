require 'test/unit'
require File.dirname(__FILE__) + '/../../lib/active_merchant'

class AuthorizedNetTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
  
  def setup
    @gateway = AuthorizedNetGateway.new({
        :login => 'X',
        :password => 'Y',
      })

    @creditcard = CreditCard.new({
      :number => '4242424242424242',
      :month => 8,
      :year => 2006,
      :name => 'Longbob Longsen',
    })
  end
  
  def test_bad_login
    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard)
        
    assert_equal Response, response.class
    assert_equal ["avs_result_code",
                  "card_code",
                  "response_code",
                  "response_reason_code",
                  "response_reason_text",
                  "transaction_id"], response.params.keys.sort

    assert_match /The merchant login ID or password is invalid/, response.message
    
    assert_equal false, response.success?
  end
  
  def test_using_test_request
    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard, :test_request => true)
        
    assert_equal Response, response.class
    assert_equal ["avs_result_code",
                  "card_code",
                  "response_code",
                  "response_reason_code",
                  "response_reason_text",
                  "transaction_id"], response.params.keys.sort
  
    assert_match /The merchant login ID or password is invalid/, response.message
    
    assert_equal false, response.success?    
  end
  
  
end