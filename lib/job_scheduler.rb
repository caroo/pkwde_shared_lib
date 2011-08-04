require 'job'
require 'job_scheduler_error'

module JobScheduler
  @@test_mode = false

  module_function

  # If set to true or :execute the scheduler execute the Job locally, if set to
  # :schedule it pushes the Job onto the Resque queue, if set to
  def test_mode(to = true)
    @@test_mode = to
  end

  # Schedule طhe the module +job+ (which has to include the ::Job module) with
  # the arguments +args+.
  def schedule(job, *args)
    Module === job and job.ancestors.include?(Job) or
      raise TypeError, "#{job.inspect} is not a Job"
    case @@test_mode
    when true, :execute
      job.perform(*args)
      job
    when :ignore
    when false, :schedule
      if Resque.enqueue(job, *args)
        job
      end
    else
      raise "illegal test_mode #{@@test_mode.inspect} was configured"
    end
  rescue SystemCallError => e
    raise JobSchedulerError.wrap(e)
  end
end
