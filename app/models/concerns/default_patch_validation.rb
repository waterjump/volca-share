# frozen_string_literal: true

# Validates that a patch differs from its model defaults for a normalized
# subset of synth parameters.
module DefaultPatchValidation
  extend ActiveSupport::Concern

  private

  def patch_is_not_default
    return if patch_default_fields.any? { |field_name| differs_from_default?(field_name) }

    errors.add(:patch, 'is not valid.')
  end

  def differs_from_default?(field_name)
    current_value = normalize_patch_value(field_name, public_send(field_name))
    default_value = normalize_patch_value(field_name, default_patch_value_for(field_name))

    current_value != default_value
  end

  def default_patch_value_for(field_name)
    self.class.fields.fetch(field_name.to_s).default_val
  end

  def normalize_patch_value(field_name, value)
    return Mongoid::Boolean.mongoize(value) if patch_default_boolean_fields.include?(field_name)
    return value.to_s if patch_default_string_fields.include?(field_name)

    value
  end

  def patch_default_fields
    self.class::DEFAULT_PATCH_FIELDS
  end

  def patch_default_boolean_fields
    self.class::DEFAULT_PATCH_BOOLEAN_FIELDS
  end

  def patch_default_string_fields
    self.class::DEFAULT_PATCH_STRING_FIELDS
  end
end
