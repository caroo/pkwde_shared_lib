# encoding: UTF-8

Capistrano::Configuration.instance(:must_exist).load do
  def each_god
    each_service(god_services) do |full_path, service_path, service_name|
      god_config = File.join(*[service_path, "setup.god"].reject(&:empty?))
      next unless File.exists?(god_config)
      remote_config = "#{current_path}/#{god_config}"
      logger.trace remote_config
      yield remote_config, service_name
    end
  end

  def god_services
    ENV['GOD_SERVICES']
  end

  def god_command
    fetch(:god_command, 'god')
  end

  namespace :god do
    namespace :master do

      desc "Start the god master process"
      desc :start do
        run "RAILS_ENV=#{rails_env} #{god_command} -l #{ god_log_dir || "/tmp" }/god.log"
      end

      desc "Stop the god master process"
      task :stop do
        run "cd #{current_path}; #{god_command} terminate; true"
      end

      desc "Status of the god master process"
      task :status do
        run "cd #{current_path}; #{god_command} status; true"
      end
    end

    desc "Start the god watches for this service"
    task :start do
      cc = CapistranoCommander.new
      cc << "cd #{current_path}"
      each_god do |remote_config, service|
        cc << "if #{god_command} 1>/dev/null status"
        cc << "then ( RAILS_ENV=#{rails_env} #{god_command} load #{remote_config} & )"
        cc << "else RAILS_ENV=#{rails_env} #{god_command} -c #{remote_config} -l #{ god_log_dir || "/tmp" }/god.log"
        cc << "fi"
      end
      run cc.cmd
    end

    # TODO this task does not terminate the god process itself.
    desc "Restart the god watches for this service"
    task :restart do
      cc = CapistranoCommander.new
      cc << "cd #{current_path}"
      each_god do |remote_config, service|
        cc << "if #{god_command} 1>/dev/null status"
        cc << "then (#{god_command} stop #{service}"
        cc << "#{god_command} remove #{service}"
        cc << "RAILS_ENV=#{rails_env} #{god_command} load #{remote_config}"
        cc << "true & )"
        cc << "else RAILS_ENV=#{rails_env} #{god_command} -c #{remote_config} -l #{ god_log_dir || "/tmp" }/god.log"
        cc << "fi"
      end
      run cc.cmd
    end

    desc "Stop the god watches for this service"
    task :stop do
      on_rollback{find_and_execute_task("god:start")}
      cc = CapistranoCommander.new
      cc << "cd #{current_path}"
      each_god do |remote_config, service|
        cc << "( if #{god_command} 1>/dev/null status"
        cc << "then #{god_command} stop #{service}"
        cc << "#{god_command} remove #{service}"
        cc << "fi & )"
      end
      run cc.cmd
    end

    desc "Show the status of the this service's god watches"
    task :status do
      cc = CapistranoCommander.new
      cc << "cd #{current_path}"
      if god_services
        each_god do |remote_config, service|
          cc << "#{god_command} status #{service}"
        end
      else
        cc << "#{god_command} status"
      end
      cc << 'true'
      run cc.cmd
    end

  end
end
