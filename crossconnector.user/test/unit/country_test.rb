require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < Test::Unit::TestCase
  fixtures :countries

  def setup
    @country = Country.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Country,  @country
  end
end
