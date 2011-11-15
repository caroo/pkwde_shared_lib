# encoding: UTF-8

Capistrano::Configuration.instance(:must_exist).load do
  
  set :pid_file, defer{"#{current_path}/tmp/pids/#{application}.pid"} unless exists?(:pid_file)
  set :log_file, defer{"#{current_path}/log/#{application}_stderror.log"} unless exists?(:log_file)
  set :rackup_file, defer{"#{current_path}/config.ru"} unless exists?(:rackup_file)
  
  namespace :deploy do
    desc "Restarts passenger standalone server."
    task :restart, :roles => :app do
      check_passenger_standalone_variables
      stop
      start
    end

    desc "Starts passenger standalone server."
    task :start, :roles => :app do
      check_passenger_standalone_variables
      run "cd #{current_path} && bundle exec passenger start -p #{port_number} -e #{stage} -R #{rackup_file} -d --pid-file #{pid_file} --log-file #{log_file} || true"
    end

    desc "Stops passenger standalone server."
    task :stop, :roles => :app do
      check_passenger_standalone_variables
      run "cd #{current_path} && bundle exec passenger stop -p #{port_number} --pid-file #{pid_file} || true"
    end

    desc "Displays the status of passenger standalone server."
    task :status, :roles => :app do
      check_passenger_standalone_variables
      run "cd #{current_path} && bundle exec passenger status -p #{port_number} --pid-file #{pid_file}"
    end
  end

  def check_passenger_standalone_variables
    empty = [:pid_file, :log_file, :rackup_file, :port_number, :stage, :user].reject{|variable| exists?(variable)}
    empty.empty? or raise ArgumentError, "Passenger standalone: following variables have to be set '#{empty.join(',')}'"
  end

end