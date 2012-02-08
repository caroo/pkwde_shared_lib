# encoding: UTF-8

require 'test_helper'
require 'pkwde'

class TaggingTest < Test::Unit::TestCase
  def test_tagging_should_have_settings_for_version_module
    assert_equal "pkwde", Pkwde::Tagging::Config.version_module_name
    assert_equal "Pkwde", Pkwde::Tagging::Config.version_module_constant_name
    Pkwde::Tagging::Config.version_module_name = 'gnb'
    assert_equal "gnb", Pkwde::Tagging::Config.version_module_name
    assert_equal "Gnb", Pkwde::Tagging::Config.version_module_constant_name

    assert_equal "pkwde", Pkwde::Tagging::Config.pivotal_project_name
    Pkwde::Tagging::Config.pivotal_project_name = "another_name"
    assert_equal "another_name", Pkwde::Tagging::Config.pivotal_project_name
  end
end