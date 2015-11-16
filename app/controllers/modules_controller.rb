class ModulesController < ApplicationController
  def streets
    render json: Street.unallocated_for_content_module_id_and_suburb(params[:module_id], params[:suburb_name])
  end
end
