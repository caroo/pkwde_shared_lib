# encoding: UTF-8

module PkwdeSharedLib
  class Railtie < Rails::Railtie
    config.pkwde_shared_lib = ActiveSupport::OrderedOptions.new

    initializer "pkwde_shared_lib.load_service_extensions" do
      JSON.create_id              = 'ruby_class'
      begin
        require 'active_support'
        ActiveSupport::JSON.backend = if ActiveSupport::VERSION::STRING >= "3.1.0" # uses MultiJson
          :json_gem
        else
          :JSONGem
        end
      rescue LoadError
      end
      require 'pkwde/field_initialisation'
      require 'pkwde/json_serialisation'
    end

    initializer "pkwde_shared_lib.load_job_scheduler" do
      require 'job_scheduler'
    end

    config.after_initialize do |app|
      if email = app.config.pkwde_shared_lib.mail_interceptor
        require 'mail_interceptor'
        MailInterceptor.receiver = email
        MailInterceptor.litmus_email = app.config.pkwde_shared_lib.litmus_email
        defined?(ActionMailer::Base) and ActionMailer::Base.register_interceptor(MailInterceptor)
      end
    end

    rake_tasks do
        load "pkwde_shared_lib/tasks/version.rake"
        load "pkwde_shared_lib/tasks/newrelic.rake"
    end
  end
end
