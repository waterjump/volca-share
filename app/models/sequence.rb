class Sequence
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :patch, inverse_of: :sequences

  embeds_many :steps, class_name: 'Step'
  accepts_nested_attributes_for :steps, limit: 16, allow_destroy: true
end
