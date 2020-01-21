# frozen_string_literal: true

module Keys
  class Patch
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Document::Taggable
    include ActiveModel::Validations
  end
end

