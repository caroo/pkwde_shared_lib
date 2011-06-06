Capistrano::Configuration.instance(:must_exist).load do
  namespace :god do
    namespace :master do
      desc "Start the god master process"
      task :start do
        cc = CapistranoCommander.new
        god_config = "#{current_path}/services/pkwde/lib/setup.god"
        cc << "cd #{current_path}/services/pkwde"
        cc << "if bundle exec god 1>/dev/null status"
        cc << "then echo 'god master already started'"
        cc << "else test -e #{god_config} && RAILS_ENV=#{rails_env} bundle exec god -c #{god_config}"
        cc << "fi"
        run cc.cmd
      end

      desc "Stop the god master process"
      task :stop do
        run "bundle exec god terminate"
      end

      desc "Terminate god and start it again"
      task :restart do
        stop
        start
      end

      desc "Status of the god master process"
      task :status do
        run "bundle exec god status; true"
      end
    end

    def each_service
      service_pathes = Dir[File.join(File.dirname(__FILE__), "..", "..", "services", "[a-z]*")]
      if env_god_services = ENV['GOD_SERVICES']
        env_god_services = env_god_services.split(/\s+/)
        service_pathes = service_pathes.select { |s| env_god_services.include?(File.basename(s)) }
      end
      service_pathes.each do |service_path|
        yield service_path, File.basename(service_path)
      end
    end

    desc "Start the god watches for this service"
    task :start do
      cc = CapistranoCommander.new
      each_service do |service_path, service|
        god_config = "#{current_path}/#{service_path}/setup.god"
        cc << "if bundle exec god 1>/dev/null status && [ -e #{god_config} ]"
        cc << "then bundle exec god load #{god_config}"
        cc << "else RAILS_ENV=#{rails_env} bundle exec god -c #{god_config}"
        cc << "fi"
      end
      run cc.cmd
    end

    desc "Restart the god watches for this service"
    task :restart do
      cc = CapistranoCommander.new
      each_service do |service_path, service|
        god_config = "#{current_path}/#{service_path}/setup.god"
        cc << "if bundle exec god 1>/dev/null status"
        cc << "then bundle exec god stop #{service}"
        cc << "bundle exec god remove #{service}"
        cc << "[ -e #{god_config} ] && bundle exec god load #{god_config}"
        cc << "true"
        cc << "else RAILS_ENV=#{rails_env} bundle exec god -c #{god_config}"
        cc << "fi"
      end
      run cc.cmd
    end

    desc "Stop the god watches for this service"
    task :stop do
      on_rollback{find_and_execute_task("god:start")}
      cc = CapistranoCommander.new
      each_service do |service_path, service|
        cc << "if bundle exec god 1>/dev/null status"
        cc << "then bundle exec god stop #{service}"
        cc << "bundle exec god remove #{service}"
        cc << "fi"
      end
      run cc.cmd
    end

    desc "Show the status of the this service's god watches"
    task :status do
      cc = CapistranoCommander.new
      each_service do |service_path, service|
        cc << "bundle exec god status #{service} || true"
      end
      run cc.cmd
    end

  end
end
