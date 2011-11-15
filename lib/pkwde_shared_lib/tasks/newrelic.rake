# encoding: UTF-8

require 'rake'
require file = File.join(File.dirname(__FILE__), *%w[.. .. pkwde.rb])
include Pkwde::Tagging

namespace :newrelic do
  namespace :deployment do
    desc "Notice newrelic about deployment"
    task :notice, :environment, :user do |task, args|
      raise ArgumentError, "I need environment argument to be set" unless args[:environment]
      require 'newrelic_rpm'
      require 'new_relic/command'
      require 'new_relic/control'
      options = {:environment => args[:environment], :user => args[:user]}
      options[:revision] = tags.last
      options[:changelog] = `git show #{tags.last}`
      begin
        NewRelic::Control.instance_variable_set(:@instance, nil)
        if File.exists? "config/newrelic.yml"
          newrelic = NewRelic::Command::Deployments.new(options)
          newrelic.run
        end
      rescue NewRelic::Command::CommandFailure => e
        Rake.application.options.silent or STDOUT.puts e.message
      end
    end
  end
end