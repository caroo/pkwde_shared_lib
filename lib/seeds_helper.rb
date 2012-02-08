require 'term/ansicolor'

module SeedsHelper
  ::Term::ANSIColor.coloring = STDERR.tty?
  include Term::ANSIColor

  $db = ActiveRecord::Base.connection.instance_variable_get(:@config)

  def plant_seed_with_id(klass, attributes, options = {})
    options |= {
      :attribute_names => %w[id],
      :force           => false,
    }
    seed = "#{klass}(#{attributes.inspect})"
    obj = options[:attribute_names].inject(klass) do |ar, an|
      an = an.to_s
      ar.where an => attributes[an]
    end.first
    if options[:force] && obj
      obj.attributes = attributes
      obj.save!
      :updated
    elsif obj
      :skipped
    else
      obj = klass.new(attributes)
      oid = attributes['id'].full? and obj.id = oid
      t = attributes['type'].full? and obj.type = t
      %w[id type].each do |an|
        v = attributes[an].full? or next
        obj.__send__("#{an}=", v)
      end
      obj.save!
      :done
    end
  rescue => e
    return "*** Planting seed #{seed} failed with #{e.class}: #{e} ***"
  end

  def seed(klassname, hashes, options = {})
    STDERR.print "Seeding #{klassname}: "
    klass =
      begin
        klassname.to_s.constantize
      rescue NameError
        STDERR.puts yellow("Skipped locally!")
        return
      end
    errors = []
    for hash in hashes
      STDERR.print\
        case r = plant_seed_with_id(klass, hash, options)
        when :done    then green '.'
        when :updated then yellow 'U'
        when :skipped then yellow 'S'
        else
          errors << r
          red 'F'
        end
    end
    STDERR.puts
    errors.full? and STDERR.puts 'Errors:', errors
  end

  def reset_from_sql(filename, dot_every = 1)
    STDERR.print "Resetting from #{filename} (#{dot_every}/.): "
    count = 0
    cmd = [ 'mysql', "-u#{$db[:username]}", "-p#{$db[:password]}", "-h#{$db[:host]}", $db[:database] ] * ' '
    IO.popen(cmd, 'w') do |output|
      File.open(filename) do |input|
        until input.eof?
          output.puts input.gets
          (count += 1) % dot_every == 0 and STDERR.print green "."
        end
      end
      STDERR.puts
    end
  end

  def create_sql_dump(filename, dot_every = 1)
    STDERR.print "Dumping to #{filename} (#{dot_every}/.): "
    count = 0
    cmd = [ 'mysqldump', "--opt", "-u#{$db[:username]}", "-p#{$db[:password]}", "-h#{$db[:host]}", $db[:database] ] * ' '
    IO.popen(cmd, 'r') do |input|
      File.open(filename, 'w') do |output|
        until input.eof?
          output.puts input.gets
          (count += 1) % dot_every == 0 and STDERR.print green "."
        end
      end
      STDERR.puts
    end
  end
end
