require File.dirname(__FILE__) + "/scenario_helper.rb"
require_relative "../lib/tasks/electoral_data_importer"
require_relative "../lib/tasks/electoral_data_exporter_helper"

describe 'dev updates electoral data using csv files', type: :feature, js: true do
  before(:each) do
    @old_stdout = $stdout
    @old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    cache_db do
      seed
      ElectoralSeeder.seed_electoral_data

      @page_with_parent = create(:page_with_parent)
      email_mp_module = create(:email_mp_module)
      create(:content_module_link, page: @page_with_parent, content_module: email_mp_module, layout_container: :sidebar)
    end
  end

  after(:each) do
    $stdout = @old_stdout
    $stderr = @old_stderr
  end

  it "should be able to look up MP after updating data" do
    export_electoral_data
    add_new_mp
    import_electoral_data

    ActionMailer::Base.deliveries = []

    visit page_path(@page_with_parent.page_sequence.campaign, @page_with_parent.page_sequence, @page_with_parent)
    fill_in 'Postcode', :with => '2010'
    fill_in 'mp_postcode', with: '2010'
    page.should have_content "MP New MP (LP) - Test Electorate"
    choose "MP New MP (LP) - Test Electorate"
  end

  def export_electoral_data
    database_details = YAML.load(ERB.new(Rails.root.join('config', 'database.yml').read).result)
    ElectoralDataExporterHelper.new("tmp", database_details['test']['username'], database_details['test']['password'], database_details['test']['database']).mysql_commands.each do |command|
      system(command)
    end
  end

  def add_new_mp
    File.open("tmp/mps.csv", "a") do |csv|
      csv << "\"13\",\"New\",\"MP\",\"mp.new@test.gov.au\",\"(02) 6277 4717\",\"\",\"PO Box 387\",,\"NSW\",\"2010\",\"\",\"(02) 4228 5899\",\"2\",\"13\",\"\",\"13\""
    end

    File.open("tmp/electorates.csv", "a") do |csv|
      csv << "\"13\",\"Test Electorate\",\"9\""
    end

    File.open("tmp/electorates_postcodes.csv", "a") do |csv|
      csv << "\"13\",\"2\",,,"
    end
  end

  def import_electoral_data
    ElectoralDataImporter.new("tmp").import_electoral_data
  end
end
