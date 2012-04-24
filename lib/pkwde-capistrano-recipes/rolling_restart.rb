# encoding: UTF-8
Capistrano::Configuration.instance(:must_exist).load do
  namespace :deploy do
    desc "Restarts the app in Passenger (waits x seconds before continues)."
    task :restart, :roles => :app, :except => {:no_release => true} do
      delay = fetch :rolling_restart_delay, 60
      servers = find_servers_for_task(current_task)
      old_host_filter = ENV['HOSTFILTER']
      servers.each do |server|
        ENV['HOSTFILTER'] = server.host
        find_and_execute_task "deploy:service_restart"
        unless servers.last == server
          logger.info "ROLLING RESTART: sleeping for #{delay} seconds"
          sleep delay
        end
      end
      ENV['HOSTFILTER'] = old_host_filter
    end
  end
end