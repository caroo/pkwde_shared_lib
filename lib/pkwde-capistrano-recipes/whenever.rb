# encoding: UTF-8

Capistrano::Configuration.instance(:must_exist).load do |config|
  def update_crontab(file = "config/schedule.rb", opts = {})
    cc = CapistranoCommander.new
    each_service do |full_path, service_path, service_name|
      cron_config = File.join(*[service_path, file].reject(&:empty?))
      next unless File.exists?(cron_config)
      remote_path = File.join(current_path, service_path)
      cc << "pushd #{remote_path}"
      cc << "(bundle exec whenever --load-file #{file} --set environment=#{stage || "development"} --update-crontab #{service_name} &)"
      cc << "popd"
    end
    run cc.cmd, opts
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
