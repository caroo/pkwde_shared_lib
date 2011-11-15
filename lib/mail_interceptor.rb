# encoding: UTF-8

require "active_support/core_ext/module/attribute_accessors"

class MailInterceptor
  mattr_accessor :receiver, :litmus_email

  def self.delivering_email(message)
    # do nothing for production
    return if Rails.env.production?
    if receiver.to_sym == :test
      ActionMailer::Base.delivery_method = :test
    else
      message.subject = "#{message.to} #{message.subject}"
      message.to = receiver
      message.cc = nil
      message.bcc = nil
    end

    litmus_email.full? do
      message.to += %w(pkw.de@t-online.de pkw.de@gmx.de pkw.de2@web.de)
      if %w(1 true yes y ja j).include? litmus_email
        message.to << "pkwde.1da4118.new@emailtests.com"
      else
        message.to << litmus_email
      end
    end
  end
end