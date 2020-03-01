# frozen_string_literal: true

module VolcaShare
  module Keys
    class PatchViewModel < ApplicationViewModel
      include AudioRegex
      include Shared

      def lfo_shape_saw
        model.lfo_shape == 'saw'
      end

      def lfo_shape_triangle
        model.lfo_shape == 'triangle'
      end

      def lfo_shape_square
        model.lfo_shape == 'square'
      end

      def index_classes
        return [] unless audio_sample.present?
        %w(has-audio)
      end
    end
  end
end
