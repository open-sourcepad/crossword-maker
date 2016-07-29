class API::V1::BaseController < ApplicationController
  before_action :create_meta

  rescue_from ActionController::ParameterMissing do |exception|
    render json: @meta.update(status: 406, errors: exception.message), status: :unprocessable_entity
  end

  # rescue_from ActiveRecord::RecordNotFound do |exception|
  #   render json: @meta.update(status: 404, errors: exception.message), status: :not_found
  # end

  private

  def create_meta
    @meta = {
      meta: {
          jsonapi: { vendor: 'crossword-maker', version: '1.0' },
          authors: ["Kenneth C <kennethc@sourcepad.com>", "Jed S <jeds@sourcepad.com>", "Andy L <andyl@sourcepad.com>", "TJ O <tjo@sourcepad.com>"],
          copyright: "SourcePad (c) #{Date.today.year}"
      },
      status: 200
    }
  end
end
