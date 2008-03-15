require File.dirname(__FILE__) + '/../test_helper'

class CreditCardTest < Test::Unit::TestCase
  include ActiveMerchant::Billing

  def test_validation
    c = CreditCard.new

    assert ! c.valid?
    assert ! c.errors.empty?
  end

  def test_valid
    c = CreditCard.new

    c.type   = "visa"
    c.number = "4779139500118580"
    c.month  = 7
    c.year   = 2008
    c.name   = "Test Mensch"

    assert c.valid?
    assert c.errors.empty?

  end

  def test_partials 
    c = CreditCard.new

    c.type   = "visa"
    c.month  = 7
    c.year   = 2008
    
    assert !c.valid?

    c.number = "11112222333344ff"
    assert !c.valid?

    c.number = "4779139500118580"
    assert c.valid?

    c.number = "111122223333444"
    assert !c.valid?
    c.number = "4779139500118580"
    assert c.valid?

    c.number = "11112222333344444"
    assert !c.valid?
    c.number = "4779139500118580"
    assert c.valid?

    c.month  = 13
    assert !c.valid?
    c.month  = 7
    assert c.valid?

    c.month  = 0
    assert !c.valid?
    c.month  = 7
    assert c.valid?

    c.year  = 2000
    assert !c.valid?
    c.year  = 2008
    assert c.valid?

    c.year  = 2020
    assert !c.valid?
    c.year  = 2008
    assert c.valid?    

  end

  def test_wrong_cardtype

    c = CreditCard.new({    
      "type"    => "visa",
      "number"  => "4779139500118580",
      "month"   => 10,
      "year"    => 2007,
    })

    assert c.valid?

    c.type = "master"
    assert !c.valid?

  end

  def test_constructor

    c = CreditCard.new({    
      "type"    => "visa",
      "number"  => "4779139500118580",
      "month"   => "10",
      "year"    => "2007",
      "name"    => "Tobias Luetke"
    })

    assert_equal "4779139500118580", c.number
    assert_equal "10", c.month
    assert_equal "2007", c.year
    assert_equal "Tobias Luetke", c.name
    assert_equal "visa", c.type        
    c.valid?

  end

end
