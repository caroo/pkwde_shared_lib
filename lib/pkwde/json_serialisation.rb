module Pkwde
  module JsonSerialisation
    module ClassMethods

      def json_create(hash)
        hash.delete(JSON.create_id)
        hash.symbolize_keys_recursive!
        new(hash)
      end
    end

    module InstanceMethods
      def as_json(options = nil)
        fields.as_json(options).merge({JSON.create_id => self.class.name})
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
