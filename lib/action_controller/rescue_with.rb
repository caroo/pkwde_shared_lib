require File.join(File.dirname(__FILE__), *%w[.. build_helper])

module ActionController
  module RescueWith
    module ClassMethods
      # status should be http response code or symbol, 2nd arg is a list of Exceptions to be rescued
      def rescue_with(status, *exception_class)
        rescue_from(*exception_class) do |exception|
          render_errors(exception, :status => status)
        end
      end
    end

    module InstanceMethods
      def render_data(data, opts = {})
        status = opts[:status] || 200
        respond_to do |wants|
          wants.json do
            render :status => status, :json => data
          end
          wants.xml do
            render :status => status, :xml => data, :root => 'response', :dasherize => false
          end

          if block_given?
            yield wants
          end
        end
      end

      def render_errors(messages, opts = {})
        status = opts[:status] || :internal_server_error
        respond_to do |wants|
          wants.json do
            render build_json_errors(messages).html_safe, :status => status
          end
          wants.xml do
            render build_xml_errors(messages).html_safe, :status => status
          end

          if block_given?
            yield wants
          end
        end
      end

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end