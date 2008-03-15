require 'test/unit'
require File.dirname(__FILE__) + '/../../lib/active_merchant'

class TrustCommerceTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
  
  def setup
    @gateway = TrustCommerceGateway.new({
      :login => 'TestMerchant',
      :password => 'password',
    })

    @creditcard = CreditCard.new({
      :number => '4111111111111111',
      :month => 8,
      :year => 2006,
      :name => 'Longbob Longsen',
    })
  end
  
  def test_bad_login
    @gateway.options[:login] = 'X'
    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard)
        
    assert_equal Response, response.class
    assert_equal ["error",
                  "offenders",
                  "status"], response.params.keys.sort

    assert_match /A field was improperly formatted, such as non-digit characters in a number field/, response.message
    
    assert_equal false, response.success?
  end
  
  def test_successful_purchase
    @gateway.options[:login] = 'TestMerchant'
    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard)
        
    assert_equal Response, response.class
    assert_equal ["avs",
                  "status",
                  "transid"], response.params.keys.sort
  
    assert_match /The transaction was successful/, response.message
    
    assert_equal true, response.success?    
  end
  
  def test_successful_authorize
    assert response = @gateway.authorize(Money.ca_dollar(100), @creditcard)
        
    assert_equal Response, response.class
    assert_equal ["avs",
                  "status",
                  "transid"], response.params.keys.sort
  
    assert_match /The transaction was successful/, response.message
    
    assert_equal true, response.success?    
  end
  
  def test_successful_capture
    assert response = @gateway.capture(Money.ca_dollar(100), '011-0022698151')
        
    assert_equal Response, response.class
    assert_equal ["status",
                  "transid"], response.params.keys.sort
  
    assert_match /The transaction was successful/, response.message
    
    assert_equal true, response.success?    
  end
  
  def test_successful_credit
    assert response = @gateway.credit(Money.ca_dollar(100), '011-0022698151')
        
    assert_equal Response, response.class
    assert_equal ["status",
                  "transid"], response.params.keys.sort
  
    assert_match /The transaction was successful/, response.message
    
    assert_equal true, response.success?    
  end
  
  def test_store_failure
    assert response = @gateway.store(@creditcard)
        
    assert_equal Response, response.class
    assert_equal ["error",
                  "offenders",
                  "status"], response.params.keys.sort

    assert_match /The merchant can't accept data passed in this field/, response.message
    
    assert_equal false, response.success?   
  end
  
  def test_unstore_failure
    assert response = @gateway.unstore('testme')
        
    assert_equal Response, response.class
    assert_equal ["error",
                  "offenders",
                  "status"], response.params.keys.sort

    assert_match /The merchant can't accept data passed in this field/, response.message
    
    assert_equal false, response.success?   
  end
  
  def test_recurring_failure
    assert response = @gateway.recurring(Money.ca_dollar(100), @creditcard, :periodicity => :weekly)
        
    assert_equal Response, response.class
    assert_equal ["error",
                  "offenders",
                  "status"], response.params.keys.sort

    assert_match /The merchant can't accept data passed in this field/, response.message
    
    assert_equal false, response.success?   
  end
  
end