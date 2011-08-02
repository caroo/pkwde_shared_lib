module PkwdeSharedLib
  class Railtie < Rails::Railtie
    initializer "pkwde_shared_lib.require_service_extensions" do
      require 'pkwde/field_initialisation'
      require 'pkwde/json_serialisation'
      require 'job'
      require 'mail_interceptor'
      Mail.register_interceptor(MailInterceptor)
    end
  end
end