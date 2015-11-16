require 'spec_helper'

describe 'import:pre_polling_booths' do
  include_context "rake"

  let!(:federal_jurisdiction){ create(:federal_jurisdiction) }
  let!(:sydney_electorate_names){ ['Grayndler', 'Kingsford Smith', 'Reid', 'Sydney', 'Warringah', 'Wentworth'] }
  let!(:electorates){ sydney_electorate_names.each{|electorate| create(:electorate, name: electorate, jurisdiction: federal_jurisdiction) } }
  let!(:postcode){ create(:postcode, number: 2000) }
  before do
    @old_stdout = $stdout
    $stdout = StringIO.new
    subject.invoke 'spec/fixtures/files/pre_polling_booths.csv'
  end
  after{ $stdout = @old_stdout }

  it "should create a single record for each booth" do
    expect(PrePollingBooth.count).to eq(1)
  end

  it "should associate the record with multiple electorates" do
    expect(PrePollingBooth.first.electorates.map(&:name).sort).to eq(sydney_electorate_names)
  end

  it "should consolidate all the opening hours and exclude hours on election day" do
    expect(PrePollingBooth.first.hours.count).to eq(8)
    expect(PrePollingBooth.first.ordered_hours.last).to eq({
      from_date: Date.new(2016, 7, 1), to_date: Date.new(2016, 7, 1),
      from_time: '8:30', to_time: '18:00'
    })
  end
end
