# encoding: UTF-8

require 'test/unit'
require 'job_scheduler'

class JobTest < Test::Unit::TestCase
  module MySmallJob
    include Job

    class << self
      def perform(arg1)
        @executed = arg1
      end

      attr_reader :executed
    end
  end

  def setup
    JobScheduler.test_mode true
  end

  def test_scheduling
    assert_equal nil, MySmallJob.executed
    JobScheduler.schedule MySmallJob, :foo
    assert_equal :foo, MySmallJob.executed
  end
end
