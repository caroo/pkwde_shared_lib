# encoding: UTF-8

require 'tins/xt/full'

module Job
  module ClassMethods
    attr_accessor :queue

    if defined?(::NewRelic)
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation

      def perform(*args, &block)
        NewRelic::Agent::ShimAgent === NewRelic::Agent.instance and NewRelic::Agent.manual_start
        NewRelic::Control.instance['resque'] = true
        perform_action_with_newrelic_trace :class_name => name, :name => 'perform', :category => :task do
          execute(*args, &block)
        end
      ensure
        Rails.logger.full?(:flush)
        NewRelic::Agent.instance.shutdown
      end
    else # if Newrelic is not present, use fallback
      def perform(*args, &block)
        execute(*args, &block)
      ensure
        Rails.logger.full?(:flush)
      end
    end

  end

  def self.included(modul)
    modul.extend ClassMethods
  end
end
