# frozen_string_literal: true

class Counter
  include Mongoid::Document
  include Mongoid::Timestamps

  store_in collection: "counters"

  field :key,   type: String
  field :value, type: Integer, default: 0

  index({ key: 1 }, unique: true)

  def self.next!(key)
    result = collection.find_one_and_update(
      { key: key },
      { '$inc' => { value: 1 } },
      upsert: true,
      return_document: :after
    )

    result.fetch('value')
  end
end
