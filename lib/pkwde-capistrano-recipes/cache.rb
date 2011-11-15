# encoding: UTF-8

Capistrano::Configuration.instance(:must_exist).load do
  namespace :cache do
    desc "Clear the Rails-Cache"
    task :clear, :roles => :app do
      run "cd #{current_release}/services/pkwde; bundle exec rake cache:clear RAILS_ENV=#{rails_env}", :once => true
    end

    desc "Generates new cached files"
    task :warmup, :roles => :web do
      run "cd #{current_release}/services/pkwde; bundle exec rake assets:cache:warmup RAILS_ENV=#{rails_env}"
    end
  end
end
