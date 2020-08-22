# frozen_string_literal: true

class ErrorsController < ApplicationController
  def not_found
    @title = 'Ya blew it.'
    render status: 404
  end

  def internal_server_error
    render status: 500
  end
end
