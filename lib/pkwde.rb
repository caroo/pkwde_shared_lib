# encoding: UTF-8

module Pkwde
  module_function
  def lib_path
    if File.exists?(path = File.expand_path("business_objects"))
      File.join(path, "lib")
    elsif File.exists?(path = File.expand_path("vendor/plugins/business_objects"))
      File.join(path, "lib")
    else
      File.expand_path("lib")
    end
  end
  
  $:.unshift lib_path unless $:.include?(lib_path)
  
  require 'pkwde/tagging'

end