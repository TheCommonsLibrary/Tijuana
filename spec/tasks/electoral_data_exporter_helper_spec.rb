require File.dirname(__FILE__) + '/../spec_helper.rb'
require_relative "../../lib/tasks/electoral_data_exporter_helper"

describe ElectoralDataExporterHelper do
  let (:electoral_data_exporter_helper) { ElectoralDataExporterHelper.new("/tmp", "root", "", "tijuana_test") }
  describe "#mysql_commands" do
    it "should generate mysql commands to export electoral data tables" do
      mysql_commands = electoral_data_exporter_helper.mysql_commands
      mysql_commands.first.should include "select * from"
      mysql_commands.first.should include "sed 's/^/\"/g;s/$/\"/g;s/\\\t/\",\"/g;s/\"NULL\"//g'"
    end
  end

  describe "#exported_files" do
    it "should return location of all exported files" do
      exported_files = electoral_data_exporter_helper.exported_files
      exported_files.should include "mps.csv"
      exported_files.should include "parties.csv"
      exported_files.should include "electorates.csv"
      exported_files.should include "regions.csv"
      exported_files.should include "senators.csv"
      exported_files.should include "jurisdictions.csv"
      exported_files.should include "postcodes_regions.csv"
      exported_files.should include "postcodes_regions.csv"
      exported_files.should include "electorates_postcodes.csv"
    end
  end
end
