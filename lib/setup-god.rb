require 'god'

def default_state_graph(w)
  # retart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 1.gigabyte
      c.times = 2
    end
  end

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end

def start_workers(group, config)
  rails_env    = ENV['RAILS_ENV'] or raise "environment variable RAILS_ENV is required"
  rails_root   = ENV['RAILS_ROOT'] = File.dirname(caller.first)
  num_workers  = config.key?(:count) && config[:count][rails_env] || 1
  name         = 'resque'
  god_log_file = rails_env == "development" ? '/tmp/god.log' : File.join(rails_root, "log/god.log")

  num_workers.times do |num|
    God.watch do |w|
      w.name         = "#{name}-#{group}-#{num}"
      w.group        = group
      w.interval     = 5.seconds
      w.env          = { "QUEUE" => group, "RAILS_ENV" => rails_env }
      w.start        = "rake resque:work"
      w.dir          = rails_root
      w.stop_signal  = "QUIT"
      w.stop_timeout = 12.hours
      w.log          = god_log_file

      default_state_graph w
    end
  end
end
