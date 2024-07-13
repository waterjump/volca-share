# frozen_string_literal:true
#
class ContactsController < ApplicationController
  def new
    @title = 'Contact Form'
  end

  def create
    captcha_passed = !Rails.env.production? || verify_recaptcha

    @clean_params = params.require(:contact).permit(:name, :email, :subject, :message)
    message_within_char_limit = @clean_params[:message].length <= 1000

    if captcha_passed && @clean_params.values.all?(&:present?) && message_within_char_limit
      respond_to do |format|
        format.html do
          submit_log_entry(@clean_params.to_h)
          redirect_to(root_path, notice: 'Your message has been successfully sent.')
        end
      end
    else
      flash[:alert] = 'Message not sent.  Please check your input and try again.'
      redirect_to new_contact_path(contact: @clean_params)
    end
  end

  private

  def submit_log_entry(data)
    Rails.application.config.contact_form_logger.info(hash_to_multiline_string(data))
  end

  def hash_to_multiline_string(hash)
    hash.map { |key, value| "CONTACTFORM   |   #{key}: #{value}" }.join("\n") + "\n#####"
  end
end
