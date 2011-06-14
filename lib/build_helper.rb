require 'builder'

module BuildHelper

  module_function

  def build_xml(opts = {})
    xml = Builder::XmlMarkup.new
    xml.instruct!
    yield xml
    xml.target!
  end

  def xml_collection_for(name, array = [])
    klass = Class.new(Array) do
      define_method(:to_xml) do |*args|
        options, = *args
        options ||= {}
        options[:indent] ||= 2
        xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
        xml.instruct! unless options[:skip_instruct]
        xml.__send__(name) do
          each do |element| element.to_xml({ :skip_instruct => true } | options) end
        end
        xml.target!
      end
    end
    klass[*array]
  end

  def build_xml_errors(messages)
    build_xml do |xml|
      xml.response do
        xml.errors do
          case
          when messages.kind_of?(Exception)
            xml.error do
              xml.message messages.to_s
              xml.class_name messages.class.name
              xml.backtrace messages.backtrace if Rails.env != 'production' && messages.respond_to?(:backtrace)
            end
          when (["ActiveModel::Errors", "ActiveRecord::Errors", "Validatable::Errors"] & messages.class.ancestors.map(&:to_s)).present?
            messages.each do |attribute, errors_array|
              errors_array.each do |error|
                xml.error do
                  xml.attribute attribute.to_s
                  xml.message error.to_s
                end
              end
            end
          else
            Array(messages).each do |message|
              xml.error do
                xml.message message.respond_to?(:to_str) ? message.to_str : message.to_s
              end
            end
          end
        end
      end
    end
  end


  def build_json_errors(messages)
    response = {}
    errors = response[:errors] = []
    # need to ask this way, because we have to support both rails 2.3.x and 3.x.x versions
    # but rails 2.3.x does not have ActiveModel
    case 
    when messages.kind_of?(Exception)
      error = { :message => messages.to_s, :class_name => messages.class.name }
      error[:backtrace] = messages.backtrace if Rails.env != 'production' && messages.respond_to?(:backtrace)
      errors << error
    when (["ActiveModel::Errors", "ActiveRecord::Errors", "Validatable::Errors"] & messages.class.ancestors.map(&:to_s)).present?
      messages.each do |attribute, errors_array|
        errors_array.each do |error_message|
          errors << { :message => error_message.to_s, :attribute => attribute.to_s }
        end
      end
    else
      Array(messages).each do |message|
        errors << { :message => message.respond_to?(:to_str) ? message.to_str : message.to_s }
      end
    end
    JSON(response)
  end

end
