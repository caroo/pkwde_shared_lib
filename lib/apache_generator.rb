#!/usr/bin/env ruby
# encoding: UTF-8

require 'fileutils'
require 'erb'
require 'tins/xt/blank'

class ApacheGenerator
  def initialize(rails_env, config_file = "variables.yml", input_dir = "conf.d", args = {}, &block)
    configuration = YAML.load_file(config_file)[rails_env.to_s]
    create_methods(configuration, args)
    Dir["#{input_dir}/**/*.erb"].each do |file|
      erb_file = File.read(file)
      erb_file.insert(0, "# GENERATED FILE, DO NOT CHANGE IT\n\n")
      compiled = ERB.new(erb_file, nil, "<>%-").result(binding)
      filename = file.sub("#{input_dir}/", "").sub(/\.erb$/, "")
      yield filename, compiled if block_given?
    end
  end

  private

    def create_methods(configuration, args = {})
      configuration.merge(args).each do |key, value|
        self.class.send(:define_method, key) { value }
      end
    end

end
