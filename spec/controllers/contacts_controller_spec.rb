# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactsController, type: :controller do
  login_user

  before { ActionMailer::Base.deliveries.clear }

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
    around do |example|
      with_modified_env CONTACT_FORM_DESTINATION_EMAIL: 'owner@example.com' do
        example.run
      end
    end

    context 'when parameters are valid' do
      it 'uses parameterized mailer delivery API' do
        mailer_proxy = double('mailer_proxy')
        message_delivery = double('message_delivery', deliver_now: true)

        expect(ContactMailer).to receive(:with).with(
          contact: {
            name: dummy_name,
            email: dummy_email,
            subject: 'Hey',
            message: dummy_message
          }
        ).and_return(mailer_proxy)
        expect(mailer_proxy).to receive(:contact_form_submission).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_now)

        post :create, params: valid_attributes
      end

      it 'sends an email' do
        expect do
          post :create, params: valid_attributes
        end.to change(ActionMailer::Base.deliveries, :count).by(1)

        mail = ActionMailer::Base.deliveries.last
        expect(mail.to).to eq(['owner@example.com'])
        expect(mail.subject).to eq('[VolcaShare Contact] Hey')
        expect(mail.body.encoded).to include(dummy_name)
        expect(mail.body.encoded).to include(dummy_message)
      end
    end

    context 'when parameters are invalid' do
      context 'when not all params are present' do
        it 'redirects back to form' do
          expect do
            post :create, params: invalid_attributes
          end.not_to change(ActionMailer::Base.deliveries, :count)

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
          expect do
            post :create, params: valid_attributes
          end.not_to change(ActionMailer::Base.deliveries, :count)

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
