# frozen_string_literal: true

class ContactMailer < ActionMailer::Base
  if Rails.env.production?
    self.delivery_method = :smtp
    self.smtp_settings = {
      address: 'smtp.sendgrid.net',
      port: 587,
      domain: 'volcashare.com',
      authentication: :plain,
      user_name: 'apikey',
      password: ENV['SENDGRID_API_KEY'],
      enable_starttls_auto: true
    }
  end

  default(
    from: proc { ENV['CONTACT_FORM_FROM_EMAIL'].presence || 'no-reply@volcashare.com' },
    to: proc { |_mailer| ENV['CONTACT_FORM_DESTINATION_EMAIL'] },
    reply_to: proc { |mailer| mailer.params.dig(:contact, :email) },
    subject: proc { |mailer| "[VolcaShare Contact] #{mailer.params.dig(:contact, :subject)}" }
  )

  def contact_form_submission
    @contact = params[:contact] || {}

    body_lines = [
      "Name: #{@contact[:name]}",
      "Email: #{@contact[:email]}",
      "Subject: #{@contact[:subject]}",
      '',
      @contact[:message].to_s
    ]

    @body_text = body_lines.join("\n")
    mail
  end
end
