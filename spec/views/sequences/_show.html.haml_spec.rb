# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'sequences/_show.html.haml', type: :view do
  before do
    @patch = FactoryBot.build(:patch_with_sequences)
    @patch.sequences.first.steps.first.step_mode = true
    @patch.sequences.first.steps.first.active_step = true
  end
  describe 'note display' do
    context 'under normal circumstances' do
      it 'is black' do
        render partial: 'sequences/show'
        expect(rendered).not_to have_css(
          '#patch_sequences_attributes_0_step_1_note_display' \
          '.grayed-out'
        )
      end
    end
    context 'when step_mode is disabled' do
      it 'is grayed out' do
        @patch.sequences.first.steps.first.step_mode = false
        render partial: 'sequences/show'
        expect(rendered).to have_css(
          '#patch_sequences_attributes_0_step_1_note_display' \
          '.grayed-out'
        )
      end
    end
    context 'when active_step is disabled' do
      it 'is grayed out' do
        @patch.sequences.first.steps.first.active_step = false
        render partial: 'sequences/show'
        expect(rendered).to have_css(
          '#patch_sequences_attributes_0_step_1_note_display' \
          '.grayed-out'
        )
      end
    end
  end
  describe 'slide light' do
    context 'when slide is enabled' do
      it 'is lit' do
        @patch.sequences.first.steps.first.slide = true
        render partial: 'sequences/show'
        expect(rendered).to have_css(
          '#patch_sequences_0_step_1_slide_light.lit'
        )
      end
    end
    context 'when slide is disabled' do
      it 'is not lit' do
        @patch.sequences.first.steps.first.slide = false
        render partial: 'sequences/show'
        expect(rendered).not_to have_css(
          '#patch_sequences_0_step_1_slide_light.lit'
        )
      end
    end
    context 'when step_mode is disabled' do
      it 'is not lit' do
        @patch.sequences.first.steps.first.slide = true
        @patch.sequences.first.steps.first.step_mode = false
        render partial: 'sequences/show'
        expect(rendered).not_to have_css(
          '#patch_sequences_0_step_1_slide_light.lit'
        )
      end
    end
    context 'when active_step is disabled' do
      it 'is not lit' do
        @patch.sequences.first.steps.first.slide = true
        @patch.sequences.first.steps.first.active_step = false
        render partial: 'sequences/show'
        expect(rendered).not_to have_css(
          '#patch_sequences_0_step_1_slide_light.lit'
        )
      end
    end
  end
  describe 'step_mode light' do
    context 'when step_mode is enabled' do
      it 'is lit' do
        render partial: 'sequences/show'
        expect(rendered).to have_css(
          '#patch_sequences_0_step_1_step_mode_light.lit'
        )
      end
    end
    context 'when step_mode is disabled' do
      it 'is not lit' do
        @patch.sequences.first.steps.first.step_mode = false
        render partial: 'sequences/show'
        expect(rendered).not_to have_css(
          '#patch_sequences_0_step_1_step_mode_light.lit'
        )
      end
    end
    context 'when active_step is disabled' do
      it 'is not lit' do
        @patch.sequences.first.steps.first.active_step = false
        render partial: 'sequences/show'
        expect(rendered).not_to have_css(
          '#patch_sequences_0_step_1_step_mode_light.lit'
        )
      end
    end
  end
  describe 'active_step light' do
    context 'when active_step is enabled' do
      it 'is lit' do
        render partial: 'sequences/show'
        expect(rendered).to have_css(
          '#patch_sequences_0_step_1_active_step_light.lit'
        )
      end
    end
    context 'when active_step is disabled' do
      it 'is not lit' do
        @patch.sequences.first.steps.first.active_step = false
        render partial: 'sequences/show'
        expect(rendered).not_to have_css(
          '#patch_sequences_0_step_1_active_step_light.lit'
        )
      end
    end
  end
end
