# encoding: UTF-8
require 'test_helper'
require 'billing_client'

class ServicePeriodTest < Test::Unit::TestCase
  include BillingClient
  def test_should_raise_error_on_invalid_year_month_string
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("2011/01") }
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("2001") }
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("2001-1") }
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("2001-10T12:10") }
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("2001-11-11T12:10") }
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("11-11") }
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("2011-11-11") }
    assert_raise(ArgumentError) { ServicePeriod.from_year_month("2011-111") }
  end

  def test_should_create_service_period_from_string
    service_period = ServicePeriod.from_year_month("2012-02")
    assert_equal 2012, service_period.year
    assert_equal 2, service_period.month
    assert_equal "2012-02", service_period.to_s
    assert_equal '#<BillingClient::ServicePeriod "2012-02">', service_period.inspect
  end

  def test_should_validate_service_period_on_creation
    assert_raise(ArgumentError){ ServicePeriod.new(2012, 0) }
    assert_raise(ArgumentError){ ServicePeriod.new(1999, 1) }
    assert_raise(ArgumentError){ ServicePeriod.new(2012, 13) }
    assert_raise(ArgumentError){ ServicePeriod.new(2051, 1) }
  end

  def test_comparison_of_service_periods
    feb_2012 = ServicePeriod.new(2012, 2)
    mar_2012 = ServicePeriod.new(2012, 3)
    jan_2013 = ServicePeriod.new(2013, 1)
    assert_equal feb_2012, feb_2012.dup
    assert_not_same feb_2012, feb_2012.dup
    assert_operator mar_2012, :>, feb_2012
    assert_operator jan_2013, :>, mar_2012
    assert_operator feb_2012, :<, jan_2013
  end

  def test_should_have_start_at
    service_period = ServicePeriod.new(2012, 2)
    assert_kind_of DateTime, service_period.start_at
    assert_equal DateTime.new(2012, 2, 1, 0, 0, 0), service_period.start_at
  end

  def test_should_have_end_at
    service_period = ServicePeriod.new(2012, 2)
    assert_kind_of DateTime, service_period.start_at
    assert_equal DateTime.new(2012, 2, 29, 23, 59, 59), service_period.end_at
  end

  def test_should_calculate_end_at_with_duration
    service_period = ServicePeriod.new(2012, 2, 6)
    assert_equal DateTime.new(2012, 7, 31, 23, 59, 59), service_period.end_at

    service_period = ServicePeriod.new(2012, 3, 2)
    assert_equal DateTime.new(2012, 4, 30, 23, 59, 59), service_period.end_at
  end

  def test_should_create_new_service_period_calling_for_duration_method
    service_period = ServicePeriod.new(2012, 2, 3)
    with_duration_6 = service_period.for_duration(6)
    assert_not_same service_period, with_duration_6
    assert_equal service_period.start_at, with_duration_6.start_at
    assert_equal 6, with_duration_6.duration
  end

  def test_call_for_duration_method_with_default_params
    service_period = ServicePeriod.new(2012, 2, 3)
    with_duration_1 = service_period.for_duration
    assert_not_same service_period, with_duration_1
    assert_equal 1, with_duration_1.duration

    service_period = ServicePeriod.new(2012, 2)
    with_duration_1 = service_period.for_duration
    assert_equal service_period, with_duration_1
    assert_not_same service_period, with_duration_1
  end

  def test_should_have_next_method
    service_period = ServicePeriod.new(2012, 2)
    assert_equal ServicePeriod.new(2012, 3), service_period.next
    assert_equal ServicePeriod.new(2012, 4), service_period.next.next

    service_period = ServicePeriod.new(2012, 1, 2)
    assert_equal ServicePeriod.new(2012, 3), service_period.next
    assert_equal ServicePeriod.new(2012, 5), service_period.next.next

    service_period = ServicePeriod.new(2012, 9, 6)
    assert_equal ServicePeriod.new(2013, 3), service_period.next
    assert_equal ServicePeriod.new(2013, 9), service_period.next.next
  end

  def test_should_have_prev_method
    service_period = ServicePeriod.new(2012, 2)
    assert_equal ServicePeriod.new(2012, 1), service_period.prev
    assert_equal ServicePeriod.new(2011, 12), service_period.prev.prev

    service_period = ServicePeriod.new(2012, 1, 2)
    assert_equal ServicePeriod.new(2011, 11), service_period.prev
    assert_equal ServicePeriod.new(2011, 9), service_period.prev.prev

    service_period = ServicePeriod.new(2012, 9, 6)
    assert_equal ServicePeriod.new(2012, 3), service_period.prev
    assert_equal ServicePeriod.new(2011, 9), service_period.prev.prev
  end

  def test_payable_method
    assert_equal true, ServicePeriod.new(2012, 2).payable?(ServicePeriod.new(2012, 2))
    assert_equal true, ServicePeriod.new(2012, 2, 6).payable?(ServicePeriod.new(2012, 2))
    assert_equal true, ServicePeriod.new(2012, 2, 6).payable?(ServicePeriod.new(2012, 8))
    assert_equal true, ServicePeriod.new(2012, 2, 6).payable?(ServicePeriod.new(2013, 2))
    assert_equal true, ServicePeriod.new(2012, 2).payable?(ServicePeriod.new(2012, 2))
    assert_equal true, ServicePeriod.new(2012, 2).payable?(ServicePeriod.new(2012, 3))
    assert_equal true, ServicePeriod.new(2012, 2).payable?(ServicePeriod.new(2012, 4))

    assert_equal false, ServicePeriod.new(2012, 2).payable?(ServicePeriod.new(2012, 1))
    assert_equal false, ServicePeriod.new(2012, 2, 6).payable?(ServicePeriod.new(2013, 3))
    assert_equal false, ServicePeriod.new(2012, 2, 6).payable?(ServicePeriod.new(2012, 7))
    assert_equal false, ServicePeriod.new(2012, 8, 6).payable?(ServicePeriod.new(2012, 2))
  end

  def test_should_call_payable_with_year_month_string
    assert_equal true, ServicePeriod.new(2012, 2).payable?("2012-02")
    assert_equal false, ServicePeriod.new(2012, 2, 6).payable?("2012-07")
  end
end
