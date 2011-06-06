Capistrano::Configuration.instance(:must_exist).load do |config|
  def update_crontab(file = "config/schedule.rb", opts = {})
    run %{
      cd #{current_path}/services;
      for s in *;
      do
        pushd $s;
        if [ -e #{file} ];
        then
          bundle exec whenever --load-file #{file} --set environment=#{stage || "development"} --update-crontab $s;
        else
          true;
        fi;
        popd;
      done
    }, opts
  rescue Capistrano::NoMatchingServersError => e
    puts e.message
  end

  def show_crontab(opts = {})
    run "crontab -l; true", opts
  rescue Capistrano::NoMatchingServersError => e
    puts e.message
  end

  def check_and_execute_cron_task(&block)
    if !exists?(:no_cron) or no_cron == false
      block.call
    end
    0
  end

  namespace :deploy do
    namespace :crontab do
      desc "Update the crontab file."
      task :update, :roles => :cron do
        check_and_execute_cron_task do
          update_crontab
        end
      end
      
      desc "Delete all cronjobs"
      task :delete, :roles => :cron do
        check_and_execute_cron_task do
          run "crontab -r"
        end
      end

      desc "Show the current installed crontab"
      task :show, :roles => :cron, :once => true do
        check_and_execute_cron_task do
          show_crontab
        end
      end
    end
  end
end
