require File.dirname(__FILE__) + '/../test_helper'

class BogusTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
  
  def setup
    @gateway = BogusGateway.new({ 
      :login => 'bogus',
      :password => 'bogus',
      :test => true,
    })
    
    @creditcard = CreditCard.new({
      :number => '1',
      :month => 8,
      :year => 2006,
      :name => 'Longbob Longsen',
    })
  end

  def test_authorize
    @gateway.capture(Money.new(1000), @creditcard)    
  end

  def test_purchase
    @gateway.purchase(Money.new(1000), @creditcard)    
  end


end
