require File.dirname(__FILE__) + '/../test_helper'

ActiveMerchant::Billing::LinkpointGateway.pem_file = File.read( File.dirname(__FILE__) + '/../mycert.pem'  ) 

class LinkpointResponseTest < Test::Unit::TestCase
  include ActiveMerchant::Billing
  
  def setup
    @gateway = LinkpointGateway.new(:store_number => 123123, :result => "GOOD")

    @creditcard = CreditCard.new({
      :number => '4111111111111111',
      :month => Time.now.month.to_s,
      :year => (Time.now + 1.year).year.to_s[2,3],
      :name => 'Captain Jack',
      :address1 => '1313 lucky lane',
      :city => 'Lost Angeles',
      :state => 'CA',
      :zip => '90210'
    })
  end
  
  
  def test_authorize
    @creditcard.number = '1'
    
    assert response = @gateway.authorize(Money.us_dollar(2400), @creditcard, :order_id => 1000)
    assert_equal Response, response.class
    #assert_equal "foo", response
    assert_equal true, response.success?
  end
  
  def test_purchase_success
    @creditcard.number = '1'
    
    assert response = @gateway.purchase(Money.us_dollar(2400), @creditcard, :order_id => 1001)
    assert_equal Response, response.class
    assert_equal true, response.success?
  end
  
  def test_purchase_decline
    @creditcard.number = '2'
    
    @gateway = LinkpointGateway.new(:store_number => 123123, :result => "DECLINE")

    assert response = @gateway.purchase(Money.us_dollar(100), @creditcard, :order_id => 1002)
    assert_equal Response, response.class
    assert_equal false, response.success?
  end
  
  def test_recurring
    @creditcard.number = '1'
    
    assert response = @gateway.recurring(Money.us_dollar(2400), @creditcard, :order_id => 1003, :installments => 12, :startdate => "immediate", :periodicity => :monthly)
    assert_equal Response, response.class
    assert_equal true, response.success?
  end
  
  
end


class LinkpointRequestTest < Test::Unit::TestCase
  include ActiveMerchant::Billing

  def setup
    @gateway = LinkpointGateway.new(:store_number => 123123, :result => "GOOD")

    @creditcard = CreditCard.new({
      :number => '4111111111111111',
      :month => Time.now.month.to_s,
      :year => (Time.now + 1.year).year.to_s[2,3],
      :name => 'Longbob Longsen',
      :address1 => '1313 lucky lane',
      :city => 'Lost Angeles',
      :state => 'CA',
      :zip => '90210'
    })
  end


  def test_purchase_is_valid_xml
    parameters = @gateway.send(:parameters, Money.us_dollar(1000), @creditcard, :ordertype => "SALE", :order_id => 1004)
  
    assert data = @gateway.send(:post_data, parameters)
    assert REXML::Document.new(data)
    assert_equal xml_purchase_fixture.size, data.size
    #assert_equal "foo", data
  end

  
  def test_recurring_is_valid_xml
    parameters = @gateway.send(:parameters, Money.us_dollar(1000), @creditcard, :ordertype => "SALE", :action => "SUBMIT", :installments => 12, :startdate => "immediate", :periodicity => "monthly", :order_id => 1006)
    assert data = @gateway.send(:post_data, parameters)
    assert REXML::Document.new(data)
    assert_equal xml_periodic_fixture.size, data.size
    #assert_equal "foo", data
  end

  
  def test_declined_purchase_is_valid_xml
    @gateway = LinkpointGateway.new(:store_number => 123123, :result => "DECLINE")
    
    parameters = @gateway.send(:parameters, Money.us_dollar(1000), @creditcard, :ordertype => "SALE", :order_id => 1005)
  
    assert data = @gateway.send(:post_data, parameters)
    assert REXML::Document.new(data)
    assert_equal xml_declined_purchase_fixture.size, data.size
    #assert_equal "foo", data
  end

  private

  def xml_purchase_fixture
   %q{<order><merchantinfo><configfile>123123</configfile></merchantinfo><creditcard><cardexpmonth>2</cardexpmonth><cardnumber>4111111111111111</cardnumber><cardexpyear>07</cardexpyear></creditcard><transactiondetails><taxexempt>Y</taxexempt><oid>1004</oid><recurring>NO</recurring><transactionorigin>ECI</transactionorigin></transactiondetails><orderoptions><ordertype>SALE</ordertype><result>GOOD</result></orderoptions><payment><chargetotal>10.00</chargetotal></payment><billing><state>CA</state><zip>90210</zip><address1>1313 lucky lane</address1><name>Longbob Longsen</name><city>Lost Angeles</city></billing></order>}
  end
  
  def xml_declined_purchase_fixture
    %q{<order><merchantinfo><configfile>123123</configfile></merchantinfo><creditcard><cardexpmonth>2</cardexpmonth><cardnumber>4111111111111111</cardnumber><cardexpyear>07</cardexpyear></creditcard><transactiondetails><taxexempt>Y</taxexempt><oid>1005</oid><recurring>NO</recurring><transactionorigin>ECI</transactionorigin></transactiondetails><orderoptions><ordertype>SALE</ordertype><result>DECLINE</result></orderoptions><payment><chargetotal>10.00</chargetotal></payment><billing><state>CA</state><zip>90210</zip><address1>1313 lucky lane</address1><name>Longbob Longsen</name><city>Lost Angeles</city></billing></order>}
  end
  
  def xml_periodic_fixture
    %q{<order><merchantinfo><configfile>123123</configfile></merchantinfo><creditcard><cardexpmonth>2</cardexpmonth><cardnumber>4111111111111111</cardnumber><cardexpyear>07</cardexpyear></creditcard><transactiondetails><taxexempt>Y</taxexempt><oid>1006</oid><recurring>NO</recurring><transactionorigin>ECI</transactionorigin></transactiondetails><orderoptions><ordertype>SALE</ordertype><result>GOOD</result></orderoptions><payment><chargetotal>10.00</chargetotal></payment><periodic><periodicity>monthly</periodicity><action>SUBMIT</action><installments>12</installments><startdate>immediate</startdate></periodic><billing><state>CA</state><zip>90210</zip><address1>1313 lucky lane</address1><name>Longbob Longsen</name><city>Lost Angeles</city></billing></order>}
  end

end