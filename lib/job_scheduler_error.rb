class JobSchedulerError < StandardError
  def self.wrap(original)
    wrapped = new("#{original.class} says: #{original.message}")
    wrapped.set_backtrace original.backtrace
    wrapped.instance_variable_set :@original, original
    wrapped
  end
end
