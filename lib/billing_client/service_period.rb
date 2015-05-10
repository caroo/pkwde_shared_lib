require 'active_model'
require 'active_model/validations'
require 'active_support'
require 'active_support/time'

module BillingClient

  class ServicePeriod
    include ActiveModel::Validations
    include Comparable

    validates_presence_of :year, :month
    validates_inclusion_of :year, :in => 2000..2050
    validates_inclusion_of :month, :in => 1..12
    validates_presence_of :duration
    validates_numericality_of :duration, :greater_than_or_equal_to  => 1, :only_integer => true

    attr_reader :year, :month, :duration

    def self.from_year_month(year_month, duration = 1)
      year_month = year_month.to_s
      year_month.match(/\A(\d{4})-(\d{2})\Z/) or
        raise ArgumentError, "wrong Format for year_month #{year_month.inspect} (YYYY-MM expected)"
      new($1.to_i, $2.to_i, duration)
    end

    def initialize(year, month, duration = 1)
      @year     = year
      @month    = month
      @duration = duration
      valid? or raise ArgumentError, "validation failed for #{self}: #{errors.full_messages.inspect}"
      freeze
    end

    def payable?(current_period)
      current_period = self.class.from_year_month(current_period)
      start_period = self
      loop do
        if start_period.start_at == current_period.start_at
          return true
        elsif start_period.start_at > current_period.start_at
          return false
        else
          start_period = start_period.next
        end
      end
    end

    def for_duration(duration = 1)
      self.class.new(year, month, duration)
    end

    def next
      next_start_at = start_at + duration.months
      self.class.new(next_start_at.year, next_start_at.month, duration)
    end

    def prev
      prev_start_at = start_at - duration.months
      self.class.new(prev_start_at.year, prev_start_at.month, duration)
    end

    def start_at
      DateTime.new(year, month)
    end
    alias begin_at start_at

    def end_at
      (start_at + (duration - 1).months).end_of_month
    end
    alias stop_at end_at

    def inspect
      "#<#{self.class.name} #{to_s.inspect}>"
    end

    def to_s
      "%04u-%02u" % [year, month]
    end

    def <=>(other)
      to_s <=> other.to_s
    end
  end
end
