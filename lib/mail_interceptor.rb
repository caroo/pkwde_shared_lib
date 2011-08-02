class MailInterceptor
  def self.delivering_email(message)
    case Rails.env
    when 'test'
      ActionMailer::Base.delivery_method = :test
    when 'development', 'staging', 'testing'
      message.subject = "#{message.to} #{message.subject}"
      message.to = if Rails.env.development?
         "#{ENV['USER'].full? || 'root'}@caroo-group.com"
      else
        "#{Rails.env}@pkw.de"
      end

      ENV["LITMUS_EMAIL"].full? do |litmus_email|
        message.to += %w(pkw.de@t-online.de pkw.de@gmx.de pkw.de2@web.de)
        if %w(1 true yes y ja j).include? litmus_email
          message.to << "pkwde.1da4118.new@emailtests.com"
        else
          message.to << litmus_email
        end
      end
      message.bcc = nil
      message.cc = nil
    when 'production'
      ;
    end

  end
end