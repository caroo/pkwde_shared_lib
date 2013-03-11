# encoding: UTF-8

Capistrano::Configuration.instance(:must_exist).load do
  # configure multistage environments
  set :stages, %w[testing staging production]

  on :load do
    set_deployment_server
    set :rails_env, defer{stage}
    default_run_options[:tty] = true
  end

  # ensure ENV['TAG'] is set before running any tasks except of testing, staging and production
  on :start, :except => stages do
    set_branch
  end

  def has_migrations?
    # run migrations when the DB flag is within the version number
    # or when the tag is not a version number
    !!(ENV['TAG'] !~ /\d{4}(?:\.\d{2}){4}/ || ENV['TAG'] =~ /DB\Z/)
  end

  def hotfix?
    !ENV["HOTFIX"].nil?
  end

  def run_migrations?
    !ENV["FORCE_MIGRATIONS"].nil?
  end

  #configure scm
  set :scm, :git
  set :scm_verbose, true
  set :deploy_via, :remote_cache
  set :copy_exclude, %w[.git]

  def set_branch
    set :branch,
      if tag = ENV['TAG']
        tag
      else
        if stage.to_s != "production"
          "master"
        else
          logger.important 'a TAG environment variable is required'
          exit 1
        end
      end
  end
  # ==================================
  # = Setzen von Release-Ordnernamen =
  # ==================================
  set :release_name do
    set :deploy_timestamped, true
    Time.now.localtime.strftime("%Y%m%dT%H%M%SR#{real_revision}")
  end

  # =============
  # = SHORTCUTS =
  # =============
  [:start, :stop, :restart, :status].each do |command|
    desc "Shortcut für 'deploy:#{command}'-Task"
    task command, :roles => :app do
      deploy.send(command)
    end
  end

  # =====================================================
  # = Variablen, die von allen Services geshared werden =
  # =====================================================
  set :use_sudo, false

  default_environment["LC_CTYPE"] = "en_US.UTF-8"

  set :deploy_to, defer{"/data/web/#{application}"}

  def set_deployment_server
    server_type = fetch(:deployment_server, "passenger")
    if server_type == 'no_op'
      logger.debug "The 'no_op' deployment strategy chosen. Falling back to capistrano's default deploy tasks"
    else
      logger.debug "Loading #{server_type.inspect} deployment strategy"
      server_strategy_file = File.join(File.dirname(__FILE__), "server_strategy", server_type.to_s)
      require server_strategy_file
    end
  rescue LoadError => e
    logger.important "Could not find server strategy file '#{server_strategy_file}'.  Falling back to capistrano's default deploy tasks"
  end

  namespace :gems do
    desc "Listet alle gems, die die Applikation benötigt"
    task :list do
      run "cd #{release_path} && bundle list"
    end

    desc "Installiert die gems im aktuellen Release-Ordner."
    task :install do
      on_rollback { run "cd #{current_path} && bundle install --binstubs" }
      run "cd #{release_path} && bundle install --binstubs"
    end

    desc "Checkt, ob alle gems installiert sind"
    task :check do
      run "cd #{release_path} && bundle check"
    end
  end
end
