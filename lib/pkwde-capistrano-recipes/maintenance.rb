# encoding: UTF-8

Capistrano::Configuration.instance(:must_exist).load do

  namespace :deploy do
    task :create_service_shareds do
      cc = CapistranoCommander.new
      # delete false links generated by deploy:finalize_update again
      cc << "rm -rf #{current_path}/log"
      cc << "rm -rf #{current_path}/tmp"
      cc << "rm -Rf #{current_path}/public/sitemaps"
      cc << "mkdir -p #{shared_path}/sitemaps"
      cc << "ln -nfs #{shared_path}/sitemaps #{current_path}/public/sitemaps"
      cc << "mkdir -p #{shared_path}/video"
      cc << "rm -Rf #{current_path}/public/videos"
      cc << "ln -nfs #{shared_path}/video #{current_path}/public/videos"
      for service in %w[pkwde api_service exportable_service]
        service_path = "services/#{service}"
        # log dir
        cc << "rm -rf #{current_path}/#{service_path}/log"
        cc << "mkdir -p #{shared_path}/#{service}/log"
        cc << "ln -s #{shared_path}/#{service}/log #{current_path}/#{service_path}/"
        # public system dir
        cc << "rm -rf #{current_path}/public/system"
        cc << "mkdir -p #{shared_path}/system"
        cc << "ln -s #{shared_path}/system #{current_path}/public/"
        # tmp pids dir
        cc << "rm -rf #{current_path}/#{service_path}/tmp/pids"
        cc << "mkdir -p #{shared_path}/#{service}/pids"
        cc << "ln -s #{shared_path}/#{service}/pids #{current_path}/#{service_path}/tmp/"
        # sugar soap config
        if service == 'pkwde'
          cc << "mkdir -p #{shared_path}/config"
          cc << "ln -sf #{shared_path}/config/sugar_soap_auth.yml #{current_path}/#{service_path}/config/sugar_soap_auth.yml"
        end
        run cc.cmd(' && ')
      end
    end

    namespace :web do
      desc <<-DESC
      Parses maintenance.html.erb and puts it into /system/maintenance.html
      DESC
      task :disable, :roles => :web, :except => { :no_release => true } do
        require 'erb'
        on_rollback { run "rm -f #{shared_path}/system/maintenance.html" }

        template_path = File.join('config', 'deploy', 'templates', 'maintenance.html.erb')
        template = File.read(template_path)
        result = ERB.new(template).result(binding)

        logger.info "*" * 80
        logger.info " Going offline at #{($going_offline = Time.now).strftime("%FT%T")} ".center(80, '*')
        logger.info "*" * 80
        put result, "#{shared_path}/system/maintenance.html", :mode => 0644
      end

      task :enable, :roles => :web, :except => { :no_release => true } do
        run "rm -f #{shared_path}/system/maintenance.html"
        logger.info "*" * 80
        logger.info " Going online at #{(going_online = Time.now).strftime("%FT%T")} (#{"%.3f secs" % ($going_offline ? going_online - $going_offline : 0.0)}) ".center(80, "*")
        logger.info "*" * 80
      end

    end
  end
end
