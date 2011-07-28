module PkwdeSharedLib
  class Railtie < Rails::Railtie
    initializer "pkwde_shared_lib.require_service_extensions" do
      require 'pkwde/service_initialisation'
      require 'pkwde/json_serialisation'
      require 'job'
    end
  end
end