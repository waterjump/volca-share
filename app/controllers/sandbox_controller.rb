# frozen_string_literal: true

class SandboxController < ApplicationController
  layout 'sandbox'

  def poc
    @title = 'WAM Sandbox POC'
  end
end
