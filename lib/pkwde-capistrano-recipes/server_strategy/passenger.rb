Capistrano::Configuration.instance(:must_exist).load do

  namespace :deploy do 
    desc "Restarts the app in Passenger."
    task :restart, :roles => :app do
      run %{
        if test -d "#{current_path}/services";
        then
          for d in #{current_path}/services/*;
          do
            test -x $d/tmp && touch $d/tmp/restart.txt;
          done
        else
          test -x #{current_path}/tmp && touch #{current_path}/tmp/restart.txt;
        fi
      }
    end

    desc "Starts the app in Passenger (which virtually does nothing)."
    task :start, :roles => :app do
      find_and_execute_task "deploy:restart"
    end
  
    desc "Stops the app in Passenger (which virtually does nothing)."
    task :stop, :roles => :app do
    end
      
    desc "Status of the app in Passenger (which virtually does nothing)."
    task :status, :roles => :app do
    end
  end
  
end
