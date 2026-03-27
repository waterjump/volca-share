# frozen_string_literal: true

class EditorPick
  include Mongoid::Document
  include Mongoid::Timestamps

  PICKABLE_TYPES = [Patch, Keys::Patch].freeze

  field :list_key, type: String, default: 'default'

  belongs_to :pickable, polymorphic: true

  index(
    { list_key: 1, pickable_type: 1, pickable_id: 1 },
    { unique: true, background: true }
  )

  validates_presence_of :list_key, :pickable
  validates_uniqueness_of :pickable_id, scope: %i[list_key pickable_type]
  validate :pickable_type_is_supported

  scope :for_list, ->(list_key) { where(list_key: list_key) }

  def self.create_from(pickable, list_key: 'default')
    create(pickable: pickable, list_key: list_key)
  end

  private

  def pickable_type_is_supported
    return if pickable.blank?
    return if PICKABLE_TYPES.any? { |type| pickable.is_a?(type) }

    errors.add(:pickable, 'must be a Patch or Keys::Patch')
  end
end
