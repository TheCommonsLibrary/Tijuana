require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "Admin cuts a list with all rules", type: :feature, js: true do
  include_context "capture_system_io"

  before(:all) { Delayed::Worker.delay_jobs = false }
  after(:all) { Delayed::Worker.delay_jobs = true }

  before(:each) do
    campaign = create(:campaign, name: 'Any Campaign')
    @push = Push.create!(name: 'Push 1', campaign: campaign)
    blast = Blast.create!(name: 'Blast 1', push: @push)
    @list = List.create!(blast: blast)

    federal_jurisdiction = create(:federal_jurisdiction)
    sydney_electorate = create(:sydney_federal, jurisdiction: federal_jurisdiction)
    banks_electorate = create(:electorate, name: 'Banks', jurisdiction: federal_jurisdiction)

    sydney_postcode = Postcode.create!(number: '2000', longitude:100.10, latitude: -38 )
    geelong_postcode = Postcode.create!(number: '3220', longitude:103.10, latitude: -36)

    sydney_postcode.electorates << sydney_electorate
    sydney_member = create(:user, :postcode => sydney_postcode)

    User.create!(email: 'mygetup@getup.org.au', password: 'password', is_admin: true)
    sign_in_as_admin
  end

  # this replaces features/cut_a_list.feature - all list cutter rules should be migrated to here
  it "should cut a list" do
    visit admin_list_cutter_edit_path(list_id: @list.id)
    select('Postcode', :from => 'filter-type')
    select('2000', :from => 'rules_postcode_within_rule_postcode_ids', :visible => false)
    select('3220', :from => 'rules_postcode_within_rule_postcode_ids', :visible => false)

    find(".filter-actions .add-filter").click

    all('.filter-by').last.select 'Electorates'
    select('Sydney Federal', :from => 'rules_electorate_rule_electorate_ids', :visible => false)
    select('Banks', :from => 'rules_electorate_rule_electorate_ids', :visible => false)

    click_button 'Show count'
    wait_until(3) { page.has_content?("SQL Generated") }
    page.should have_content("FOUND 1 MEMBERS")
    
    click_button 'Save'
    page.should have_content("Edit List")
    current_path.should == admin_push_path(@push.id)
  end
end
