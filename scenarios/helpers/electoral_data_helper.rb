require 'yaml'
require_relative "../../lib/tasks/electoral_data_importer"
require_relative "../../lib/tasks/electoral_data_exporter_helper"

module ElectoralDataHelper
end

RSpec.configuration.include ElectoralDataHelper, :type => :feature
