# encoding: UTF-8
require 'active_support'
require 'active_support/core_ext/class/attribute_accessors'

module Pkwde
  # Include this module to mark it for copying in #clone and #dup via the Initialisation module
  module CopyViaInitialisation
  end

  class ::Array
    include CopyViaInitialisation
  end

  class ::Hash
    include CopyViaInitialisation
  end

  class ::String
    include CopyViaInitialisation
  end

  module FieldInitialisation
    include CopyViaInitialisation

    module ClassMethods
      def define_fields(*field_names)
        attr_accessor(*field_names)
        cattr_accessor :field_names unless respond_to? :field_names
        self.field_names ||= []
        self.field_names.concat(field_names.map(&:to_sym))
      end
      alias define_field define_fields
    end

    module InstanceMethods
      def initialize(args = {})
        update_fields args
      end

      def update_fields(args = {})
        args.each do |name, value|
          __set_field_value__ name, value
        end
      end

      def fields
        self.class.field_names.inject({}) do |fields, field_name|
          field_value = __get_field_value__ field_name
          fields[field_name.to_sym] = field_value unless field_value.nil?
          fields
        end
      end

      if RUBY_VERSION < '1.8.7'
        def eql?(other)
          other.respond_to?(:fields) && fields.sort_by { |n,| n.to_s }.eql?(other.fields.sort_by { |n,| n.to_s })
        end
      else
        def eql?(other)
          other.respond_to?(:fields) && fields.eql?(other.fields)
        end
      end

      alias == eql?

      def hash
        fields.hash
      end

      private

      def initialize_copy(orig)
        self.class.field_names.each do |field_name|
          orig_field = orig.__get_field_value__(field_name)
          cloned_field = CopyViaInitialisation === orig_field ? orig_field.deep_dup : orig_field
          __set_field_value__ field_name, cloned_field
        end
      end

      protected

      def __set_field_value__(name, value)
        writer = "#{name}="
        if respond_to?(writer)
          __send__ writer, value
        else
          instance_variable_set "@#{name}", value
        end
      end

      def __get_field_value__(name)
        if respond_to?(name)
          __send__ name
        else
          instance_variable_get "@#{name}"
        end
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end

  end
end
