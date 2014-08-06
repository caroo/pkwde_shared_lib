# encoding: UTF-8

require 'rubygems'
require 'capistrano'
require 'capistrano/ext/multistage'

class CapistranoCommander
  def initialize
    @cmds = []
  end

  def run(*cmds)
    @cmds.concat cmds
  end

  alias << run

  def cmd(separator = '; ')
    @cmds * separator
  end
end

require 'fileutils'

# yield full_path, path relative_to_current, directory_name
def each_service(filter = nil)
  current_path = FileUtils.pwd
  filter_services = case filter
    when nil then []
    when String then filter.strip.split(/\s+/)
    when Array then filter
  end

  service_pathes =
    if File.exists?("services")
      Dir["services/[a-z]*"].select { |path| File.directory?(path) }
    else
      [ '' ] # for current directory
    end
  service_pathes.each do |service_path|
    full_path = File.join(*[current_path, service_path].reject(&:empty?))
    dirname = File.basename(full_path)
    if filter_services.empty? || filter_services.include?(dirname)
      yield full_path, service_path, dirname
    end
  end
end

require 'pkwde-capistrano-recipes/shared'
require 'pkwde-capistrano-recipes/god'
require 'pkwde-capistrano-recipes/utils'
require 'pkwde-capistrano-recipes/whenever'
require 'pkwde-capistrano-recipes/cache'
require 'pkwde-capistrano-recipes/maintenance'
require 'pkwde-capistrano-recipes/apache'
require 'pkwde-capistrano-recipes/nginx'
begin
  require 'new_relic/recipes'
rescue LoadError => e
  warn "Cannot load NewRelic Recipes. Continue to deploy without these recipes..."
end
