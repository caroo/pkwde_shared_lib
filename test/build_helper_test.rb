# encoding: UTF-8

require 'test_helper'
require 'action_view'
module Rails
  def self.logger
  end
end
require 'build_helper'
require 'active_record'

class BuildHelperTest < ActionView::TestCase
  include ActionDispatch::Assertions::TagAssertions
  helper BuildHelper

  # Tableless active record to test the error behaviour
  class ErrorExample < ActiveRecord::Base
    def self.columns() @columns ||= []; end
    def self.column(name, sql_type = nil, default = nil, null = true)
      columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
    end
    column :identifier, :string
    validates_presence_of :identifier
  end

  def setup
    Rails.stubs(:env).returns("development")
  end

  def test_build_error_for_exception_xml
    e = begin; raise StandardError, "Bad habit"; rescue ; $! ; end
    body = build_xml_errors(e)
    @response = build_response(body)
    assert_tag :tag => "response", :child => { :tag => "errors", :child => { :tag => "error" } }
    assert_tag :tag => "class_name", :content => "StandardError"
    assert_tag :tag => "message", :content => "Bad habit"
    assert_tag :tag => "backtrace"
  end

  def test_build_error_for_exception_json
    e = begin; raise StandardError, "Bad habit"; rescue ; $! ; end
    body = JSON(build_json_errors(e))
    assert_not_nil error = body["errors"].first
    assert_equal 'StandardError', error["class_name"]
    assert_equal 'Bad habit', error["message"]
    assert_not_nil error["backtrace"]
  end

  def test_build_error_for_active_support_errors_xml
    ee = ErrorExample.new; ee.valid?
    body = build_xml_errors(ee.errors)
    @response = build_response(body)
    assert_tag :tag => "response", :child => { :tag => "errors", :child => { :tag => "error" } }
    assert_tag :tag => "attribute", :content => "identifier"
    assert_tag :tag => "message", :content => ee.errors["identifier"].first
  end

  def test_build_error_for_active_support_errors_json
    ee = ErrorExample.new; ee.valid?
    body = JSON(build_json_errors(ee.errors))
    assert_not_nil error = body["errors"].first
    assert_equal "identifier", error["attribute"]
    assert_equal ee.errors["identifier"].first, error["message"]
  end

  def test_build_error_for_strings_xml
    body = build_xml_errors(["Error 0", "Error 1"])
    @response = build_response(body)
    assert_tag :tag => "response", :child => { :tag => "errors", :children => { :count => 2, :only => { :tag => "error" } } }
    assert_tag :tag => "message", :content => "Error 0"
    assert_tag :tag => "message", :content => "Error 1"
  end

  def test_build_error_for_strings_json
    body = JSON(build_json_errors(["Error 0", "Error 1"]))
    assert_equal "Error 0", body["errors"][0]["message"]
    assert_equal "Error 1", body["errors"][1]["message"]
  end

  def build_response(body)
    response = ActionController::TestResponse.new
    response.body = body
    response.content_type = 'application/json'
    response
  end
end
