Capistrano::Configuration.instance(:must_exist).load do |config|
  require "nginx_generator"
  set :nginx_bin, defer{fetch(:nginx_path, "/home/#{user}/nginx/sbin/nginx")}
  set :nginx_config, defer{fetch(:nginx_config_path, "/home/#{user}/nginx/conf/includes")}
  set :nginx_config_backup, defer{ "#{nginx_config}.back"}
  
  namespace :nginx do
    namespace :config do
      
      desc "Updates nginx configurations"
      task :update do |variable|
        transaction do
          upload
          test_configuration
          find_and_execute_task "nginx:restart"
        end
      end
      
      task :test_configuration do
        run "#{nginx_bin} -t"
      end
      
      task :upload, :roles => :app do
        with_newrelic = find_servers(:only => {:use_newrelic => true})
        without_newrelic = find_servers(:except => {:use_newrelic => true})
        run "rm -rf /tmp/nginx && mkdir -p /tmp/nginx"
        
        if with_newrelic.present?
          NginxGenerator.new(rails_env, nginx_env_config, nginx_config_templates, {:use_newrelic => true}){|file_name, file_content|
            run "mkdir -p /tmp/nginx/#{File.dirname(file_name)}"
            put file_content, "/tmp/nginx/#{file_name}", :MODE => "664", :hosts => with_newrelic.map(&:host)
          }
        end
        if without_newrelic.present?
          NginxGenerator.new(rails_env, env_config, config_templates, {:use_newrelic => false}){|file_name, file_content|
            run "mkdir -p /tmp/nginx/#{File.dirname(file_name)}"
            put file_content, "/tmp/nginx/#{file_name}", :MODE => "664", :hosts => without_newrelic.map(&:host)
          }
        end
        
        run "rm -rf #{nginx_config_backup} && mv #{nginx_config} #{nginx_config_backup} && mv /tmp/nginx #{nginx_config}"
        on_rollback do
          run "test -d #{nginx_config_backup} && rm -rf #{nginx_config} && mv #{nginx_config_backup} #{nginx_config}"
          find_and_execute_task "nginx:restart"
        end
      end
    end # end namespace nginx/config
    
    # namespace nginx without reload, because it doesn't work properly
    %w[stop quit reopen].each do |command|
      task command do
        run "#{nginx_bin} -s #{command}"
      end
    end

    desc "start nginx server"
    task :start do
      # capistrano will hangup on nginx start
      run "#{nginx_bin} &"
    end

    desc "checks config and if okay, stop and start of nginx"
    task :restart do
      find_and_execute_task "nginx:config:test_configuration"
      stop
      start
    end
  end # end namespace nginx
end # end capistrano configuration
