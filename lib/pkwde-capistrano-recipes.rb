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
  filtered_paths = case filter
  when nil then []
  when String then filter.strip.split(/\s+/)
  when Array then filter
  end
  current_path = FileUtils.pwd
  service_paths = File.exists?("services") ? Dir["services/[a-z]*"].select { |path| File.directory?(path) } : [""]
  service_paths.each do |service_path|
    full_path = File.join(*[current_path, service_path].reject(&:empty?))
    dirname = File.basename(full_path)
    next if filtered_paths.include?(dirname)
    yield full_path, service_path, dirname
  end
end

require 'pkwde-capistrano-recipes/shared'
require 'pkwde-capistrano-recipes/god'
require 'pkwde-capistrano-recipes/utils'
require 'pkwde-capistrano-recipes/whenever'
require 'pkwde-capistrano-recipes/cache'
require 'pkwde-capistrano-recipes/maintenance'
require 'pkwde-capistrano-recipes/apache'
begin
  require 'new_relic/recipes'
rescue LoadError => e
  warn "Cannot load NewRelic Recipes. Continue to deploy without these recipes..."
end