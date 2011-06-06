Capistrano::Configuration.instance(:must_exist).load do |config|
  require "apache_generator"
  # set required variables
  set :env_config, defer{fetch(:apache_env_config, File.join(File.dirname(__FILE__), *%w[.. .. config apache variables.yml]))}
  set :config_templates, defer{fetch(:apache_config_templates, File.join(File.dirname(__FILE__), *%w[.. .. config apache conf.d]))}
  set :httpd, defer{fetch :httpd_path, "/etc/init.d/httpd"}
  set :apache_config, defer{fetch(:apache_config_path, "/etc/httpd/conf.d")}
  set :apache_config_backup, defer{ "#{apache_config}.back"}
  
  namespace :apache do
    namespace :config do
      
      desc "Updates apache configurations"
      task :update do |variable|
        transaction do
          upload
          reload
        end
      end
      
      task :upload, :roles => :app do
        with_newrelic = find_servers(:only => {:use_newrelic => true})
        without_newrelic = find_servers(:except => {:use_newrelic => true})
        run "rm -rf /tmp/apache && mkdir -p /tmp/apache"
        
        if with_newrelic.present?
          ApacheGenerator.new(rails_env, env_config, config_templates, {:use_newrelic => true}){|file_name, file_content|
            put file_content, "/tmp/apache/#{file_name}", :MODE => "664", :hosts => with_newrelic.map(&:host)
          }
        end
        if without_newrelic.present?
          ApacheGenerator.new(rails_env, env_config, config_templates, {:use_newrelic => false}){|file_name, file_content|
            put file_content, "/tmp/apache/#{file_name}", :MODE => "664", :hosts => without_newrelic.map(&:host)
          }
        end
        
        run "rm -rf #{apache_config_backup} && mv #{apache_config} #{apache_config_backup} && mv /tmp/apache #{apache_config}"
        on_rollback {run "test -d #{apache_config_backup} && rm -rf #{apache_config} && mv #{apache_config_backup} #{apache_config}"}
      end
      
      task :reload do
        run "sudo #{httpd} reload"
        on_rollback { run "sudo #{httpd} reload"}
      end
    end
    
    %w[start restart graceful graceful-stop stop reload].each do |command|
      task command do
        run "sudo #{httpd} #{command}"
      end
    end
  end
end