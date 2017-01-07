class Step
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :sequence, inverse_of: :steps

  field :note, type: Integer
  field :step_mode, type: Boolean
  field :slide, type: Boolean
  field :active_step, type: Boolean
end
