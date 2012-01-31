# encoding: UTF-8

require 'tins/xt/full'

module Job
  extend ActiveSupport::Concern

  included do
    alias execute perform
  end

  module ClassMethods
    attr_accessor :queue

    if defined?(::NewRelic)
      include NewRelic::Agent::Instrumentation::ControllerInstrumentation

      def around_perform(*args)
        NewRelic::Agent::ShimAgent === NewRelic::Agent.instance and NewRelic::Agent.manual_start
        NewRelic::Control.instance['resque'] = true
        perform_action_with_newrelic_trace :class_name => name, :name => 'perform', :category => :task do
          yield(*args)
        end
      ensure
        Rails.logger.full?(:flush)
        NewRelic::Agent.instance.shutdown
      end
    end
  end
end
