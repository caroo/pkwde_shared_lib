module JobScheduler
  def self.schedule(job, *args)
    Module === job and job.ancestors.include?(Job) or
      raise TypeError, "#{job.inspect} is not a Job"
    if Resque.enqueue(job, *args)
      job
    end
  end
end