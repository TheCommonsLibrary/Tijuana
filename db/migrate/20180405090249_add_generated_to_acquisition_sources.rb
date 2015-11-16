class AddGeneratedToAcquisitionSources < ActiveRecord::Migration
  def change
    add_column :acquisition_sources, :generated, :boolean, default: false 
  end
end
