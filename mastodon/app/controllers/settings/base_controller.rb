# frozen_string_literal: true

class Settings::BaseController < ApplicationController
  layout 'application'

  before_action :authenticate_user!

  private

  def require_not_suspended!
    forbidden if current_account.unavailable?
  end
end
