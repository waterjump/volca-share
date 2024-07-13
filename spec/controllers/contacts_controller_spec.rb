# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactsController, type: :controller do
  login_user

  let(:dummy_name) { FFaker::Name.name }
  let(:dummy_email) { FFaker::Internet.email }
  let(:dummy_message) { FFaker::Lorem.paragraph }
  let(:valid_attributes) do
    {
      contact: {
        name: dummy_name,
        email: dummy_email,
        subject: 'Hey',
        message: dummy_message
      }
    }
  end
  let(:invalid_attributes) do
    {
      contact: {
        name: dummy_name,
        subject: 'Hey',
        email: nil,
        message: dummy_message
      }
    }
  end

  describe 'GET #new' do
    it 'sets title' do
      get :new
      expect(assigns(:title)).to eq('Contact Form')
    end
  end

  describe 'POST #create' do
    context 'when parameters are valid' do
      it 'logs message' do
        expect(Rails.application.config.contact_form_logger).to(
          receive(:info).with(include(dummy_name))
        )

        post :create, params: valid_attributes
      end
    end

    context 'when parameters are invalid' do
      context 'when not all params are present' do
        it 'redirects back to form' do
          expect(Rails.application.config.contact_form_logger).not_to receive(:info)
          post :create, params: invalid_attributes

          expect(response).to(
            redirect_to(
              new_contact_path(invalid_attributes)
            )
          )
        end
      end

      context 'when message exceeds 1000 characters' do
        let(:dummy_message) { FFaker::Lorem.characters(1_001) }

        it 'redirects back to form' do
          expect(Rails.application.config.contact_form_logger).not_to receive(:info)
          post :create, params: valid_attributes

          expect(response).to(
            redirect_to(
              new_contact_path(valid_attributes)
            )
          )
        end
      end
    end
  end
end
