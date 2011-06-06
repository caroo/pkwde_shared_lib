require 'rubygems'
require 'capistrano'

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