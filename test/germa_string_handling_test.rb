# encoding: UTF-8

require 'test_helper'
require 'pkwde_shared_lib'

class GermaStringHandlingTest < Test::Unit::TestCase
  def test_should_transform_string_with_german_umlauts_and_spaces_to_url_friendly_string
    assert_equal "autohaus-jaensch-gmbh", "Autohaus Jänsch GmbH".make_url_friendly
    assert_equal "koelner-strassenamt-fuer-aehnliche-kurven", "Kölner Straßenamt für ähnliche Kurven".make_url_friendly
  end

  def test_should_transform_string_with_german_umlauts_and_spaces_to_css_friendly_string
    assert_equal "autohaus-jaensch-gmbh", "Autohaus Jänsch GmbH".make_css_friendly
    assert_equal "koelner-strassenamt-fuer-aehnliche-kurven", "Kölner Straßenamt für ähnliche Kurven".make_css_friendly
    assert_equal "coupe","Coupé".make_css_friendly
    assert_equal "gelaendewagen","Geländewagen".make_css_friendly
  end
end
