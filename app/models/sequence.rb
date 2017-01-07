class Sequence
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :patch, inverse_of: :sequences

  embeds_many :steps, class_name: 'Step'
end
