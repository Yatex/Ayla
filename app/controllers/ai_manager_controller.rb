class AiManagerController < ApplicationController
  before_action :authenticate_user!

  def show
    redirect_to strategy_path
  end

  def update
    redirect_to strategy_path
  end
end
