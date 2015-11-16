require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe AskStatsTable do
  let!(:campaign) { create(:campaign) }
  let!(:sequences) {
    3.times.map do |i|
      seq = create(:page_sequence, :campaign => campaign, :name => "Dummy Page Sequence Name-#{i}")
      seq.pages << page = create(:page, :page_sequence => seq)
      page.content_modules << create(:html_module)
      page.content_modules << create(:donation_module)
      page.tag_list = "one, two, three"
      page.save
      seq
    end
  }
  let!(:stats) { Campaign.find_by_sql(campaign.build_stats_query) }
  let!(:table) { AskStatsTable.new(stats) }

  it "should extract all the ask modules from a set of page sequences and map them to rows" do
    table.rows.count.should == 3
    test_row = table.rows.sort {|a,b| a[1] <=> b[1] }.first
    created_date = test_row.shift
    test_row.should == [
      "Dummy Page Sequence Name-0",
      "Unnamed Page",
      "one, two, three",
      "DonationModule",
      0,
      0,
      "$0.00",
      nil
    ]
  end

  it "handles deleted pages by displaying them" do
    sequences.first.pages.first.destroy
    table.rows.count.should == 3
  end
end
