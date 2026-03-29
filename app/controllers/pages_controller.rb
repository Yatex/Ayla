class PagesController < ApplicationController
  def home
    redirect_to overview_path if user_signed_in?
  end
end
