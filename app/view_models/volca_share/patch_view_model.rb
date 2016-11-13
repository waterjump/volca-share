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
  end
end
