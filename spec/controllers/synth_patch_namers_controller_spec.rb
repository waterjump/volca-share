# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SynthPatchNamersController, type: :controller do
  describe 'GET #name' do
    let(:patch_name_instance) { instance_double(PatchNamer, call: 'kate bush') }

    it 'calls PatchNamer service class' do
      expect(PatchNamer).to receive(:new).and_return(patch_name_instance)

      get :name, params: { format: :json }
    end

    it 'return json' do
      allow(PatchNamer).to receive(:new).and_return(patch_name_instance)

      get :name, params: { format: :json }

      expect(JSON.parse(response.body)).to(eq('name' => patch_name_instance.call))
    end
  end
end

