# encoding: UTF-8

Capistrano::Configuration.instance(:must_exist).load do
  require 'thread'
  namespace :util do
    namespace :log do
      desc "tail log files"
      task :tail, :roles => :app do
        run "tail -Fn 150 #{current_path}/services/*/log/#{stage}.log" do |channel, stream, data|
          puts "#{channel[:host]}: #{data}"
          break if stream == :err
        end
      end
    end

    namespace :newrelic do
      desc "Record a deployment in New Relic RPM (rpm.newrelic.com)"
      task :notice_deployment, :roles => :app, :except => {:no_release => true } do
        system %{bundle exec rake "newrelic:deployment:notice[#{rails_env}, #{ENV["USER"]}]"}
      end
    end
  end
end
