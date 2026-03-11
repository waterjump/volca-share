# frozen_string_literal:true
#
class ContactsController < ApplicationController
  def new
    @title = 'Contact Form'
  end

  def create
    captcha_passed = !Rails.env.production? || verify_recaptcha

    @clean_params =
      params.require(:contact).permit(:name, :email, :subject, :message)

    message_within_char_limit = @clean_params[:message].length <= 1000

    valid_submission =
      captcha_passed &&
      @clean_params.values.all?(&:present?) &&
      message_within_char_limit

    if valid_submission
      respond_to do |format|
        format.html do
          ContactMailer.with(
            contact: @clean_params.to_h.symbolize_keys
          ).contact_form_submission.deliver_now

          redirect_to(
            root_path,
            notice: 'Your message has been successfully sent.'
          )
        end
      end
    else
      flash[:alert] =
        'Message not sent.  Please check your input and try again.'

      redirect_to new_contact_path(contact: @clean_params)
    end
  end

end
