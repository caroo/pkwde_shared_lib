require 'resque'

module JobScheduler
  @@test_mode = false

  module_function

  def test_mode(to = true)
    @@test_mode = to
  end

  def schedule(job, *args)
    Module === job and job.ancestors.include?(Job) or
      raise TypeError, "#{job.inspect} is not a Job"
    if Resque.enqueue(job, *args)
      job
    end
  rescue Errno::ECONNREFUSED => e
    @@test_mode or raise e
  end

end