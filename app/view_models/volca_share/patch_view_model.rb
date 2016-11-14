module VolcaShare
  class PatchViewModel < ApplicationViewModel
    def vco_group_one
      return true if vco_group == 'one'
      false
    end

    def vco_group_two
      return true if vco_group == 'two'
      false
    end

    def vco_group_three
      return true if vco_group == 'three'
      false
    end

    def checked?(field)
      return { checked: true } if model.send(field)
      {}
    end

    def username
      model.user.username
    end

    def description
      return unless model.notes.present?
      return model.notes.squish if model.notes.squish.length <= 180
      model.notes[0..80].squish + '...'
    end
  end
end
