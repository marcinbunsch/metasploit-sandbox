class TargetsController < ActionController::Base

  def index
    render params[:id]
  end

end

