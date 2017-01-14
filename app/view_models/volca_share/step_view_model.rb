module VolcaShare
  class StepViewModel < ApplicationViewModel
    def step_mode_checked
      return { checked: true } if model.step_mode
      {}
    end

    def slide_checked
      return { checked: true } if model.slide
      {}
    end

    def active_step_checked
      return { checked: true } if model.active_step
      {}
    end
  end
end
