Capistrano::Configuration.instance(:must_exist).load do |config|
  require "nginx_generator"
  set :nginx, defer{fetch :httpd_path, "/home/#{user}/nginx/sbin/nginx"}
  set :nginx_config, defer{fetch(:nginx_config_path, "/etc/httpd/conf.d")}
  set :nginx_config_backup, defer{ "#{nginx_config}.back"}
  
  namespace :nginx do
    namespace :config do
      
      desc "Updates nginx configurations"
      task :update do |variable|
        transaction do
          upload
          test
          reload
        end
      end
      
      task :test do
        run "#{nginx} -t"
      end
      
      task :upload, :roles => :app do
        with_newrelic = find_servers(:only => {:use_newrelic => true})
        without_newrelic = find_servers(:except => {:use_newrelic => true})
        run "rm -rf /tmp/nginx && mkdir -p /tmp/nginx"
        
        if with_newrelic.present?
          NginxGenerator.new(rails_env, env_config, config_templates, {:use_newrelic => true}){|file_name, file_content|
            put file_content, "/tmp/nginx/#{file_name}", :MODE => "664", :hosts => with_newrelic.map(&:host)
          }
        end
        if without_newrelic.present?
          NginxGenerator.new(rails_env, env_config, config_templates, {:use_newrelic => false}){|file_name, file_content|
            put file_content, "/tmp/nginx/#{file_name}", :MODE => "664", :hosts => without_newrelic.map(&:host)
          }
        end
        
        run "rm -rf #{nginx_config_backup} && mv #{nginx_config} #{nginx_config_backup} && mv /tmp/nginx #{nginx_config}"
        on_rollback do
          run "test -d #{nginx_config_backup} && rm -rf #{nginx_config} && mv #{nginx_config_backup} #{nginx_config}"
          find_and_execute_task "nginx:config:reload"
        end
      end
      
      task :reload do
        run "#{nginx} -s reload"
      end
    end # end namespace nginx/config
    
    # namespace nginx
    %w[stop quit reopen reload].each do |command|
      task command do
        run "#{nginx} -s #{command}"
      end
    end
  end # end namespace nginx
end # end capistrano configuration