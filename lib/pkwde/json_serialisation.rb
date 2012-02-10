# encoding: UTF-8

module Pkwde
  module JsonSerialisation
    module ClassMethods

      def json_create(hash)
        hash.delete(JSON.create_id)
        hash.symbolize_keys_recursive!
        new(hash)
      end

      attr_accessor :create_class
    end

    module InstanceMethods
      def as_json(options = nil)
        object = fields.as_json(options)
        case create_class = self.class.create_class
        when false
          ;
        when nil
          object.update({JSON.create_id => self.class.name})
        else
          object.update({JSON.create_id => create_class.to_s })
        end
        object
      end

      def to_json(*a)
        as_json.to_json(*a)
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
