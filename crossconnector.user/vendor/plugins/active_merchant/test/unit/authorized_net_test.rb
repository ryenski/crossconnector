require File.dirname(__FILE__) + '/../test_helper'

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

  def test_purchase_success    
    @creditcard.number = 1

    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard)
    assert_equal Response, response.class
    assert_equal '#0001', response.params['receiptid']
    assert_equal true, response.success?
  end

  def test_purchase_error
    @creditcard.number = 2

    assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard, :order_id => 1)
    assert_equal Response, response.class
    assert_equal '#0001', response.params['receiptid']
    assert_equal false, response.success?

  end
  
  def test_purchase_exceptions
    @creditcard.number = 3 
    
    assert_raise(Error) do
      assert response = @gateway.purchase(Money.ca_dollar(100), @creditcard, :order_id => 1)    
    end
  end
  
  def test_amount_style
   assert_equal '10.34', @gateway.send(:amount, Money.new(1034))
   assert_equal '10.34', @gateway.send(:amount, 1034)
                                                      
   assert_raise(ArgumentError) do
     @gateway.send(:amount, '10.34')
   end
  end                                                         
  
  
  def test_purchase_is_valid_csv

   params = { 
     :amount => "1.01",
   }                                                         
   
   @gateway.send(:add_creditcard, params, @creditcard)

   assert data = @gateway.send(:post_data, 'AUTH_ONLY', params)
   assert_equal post_data_fixture.size, data.size
  end                                                         
  
  private
  
  def post_data_fixture
    'x_delim_data=TRUE&x_password=Y&x_encap_char=%24&x_type=AUTH_ONLY&x_login=X&x_version=3.1'
  end

end