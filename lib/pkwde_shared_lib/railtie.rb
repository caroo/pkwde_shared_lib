module PkwdeSharedLib
  class Railtie < Rails::Railtie
    initializer "pkwde_shared_lib.load_service_extensions" do
      JSON.create_id              = 'ruby_class'
      begin
        ActiveSupport::JSON.backend = 'JSONGem'
      rescue LoadError
      end
      require 'pkwde/field_initialisation'
      require 'pkwde/json_serialisation'
    end

    initializer "pkwde_shared_lib.load_job_scheduler" do
      require 'job_scheduler'
    end

    initializer "pkwde_shared_lib.load_mail_extensions" do
      require 'mail_interceptor'
      defined?(Mail) and Mail.register_interceptor(MailInterceptor)
    end

    rake_tasks do
        load "pkwde_shared_lib/tasks/version.rake"
    end
  end
end
