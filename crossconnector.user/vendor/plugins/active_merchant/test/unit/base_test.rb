require File.dirname(__FILE__) + '/../test_helper'

class BaseTest < Test::Unit::TestCase
  include ActiveMerchant::Billing

  def test_get_gateway_by_name
    assert_equal BogusGateway, Base.gateway(:bogus)
  end

  def test_get_moneris_by_name
    assert_equal MonerisGateway, Base.gateway(:moneris)
  end

  def test_get_authorized_net_by_name
    assert_equal AuthorizedNetGateway, Base.gateway(:authorized_net)
  end

end
