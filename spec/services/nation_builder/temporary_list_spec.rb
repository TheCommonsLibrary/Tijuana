require "spec_helper"

describe NationBuilder::TemporaryList, :vcr do
  it "should allow creation of multiple lists simultaneously without error" do
    NationBuilder::TemporaryList.create ["my first list"]
    NationBuilder::TemporaryList.create ["my second list"]
  end

  it "adds multiple tags" do
    list = NationBuilder::TemporaryList.create ["stuff_sync", "things_sync"]
    list.should_receive(:apply_tag).with("stuff_sync")
    list.should_receive(:apply_tag).with("things_sync")
    list.add_people [1]
    list.apply_tags!
  end

  it "only syncs tags ending in 'sync'" do
    list = NationBuilder::TemporaryList.create ["stuff_sync", "things"]
    list.should_receive(:apply_tag).with("stuff_sync")
    list.should_not_receive(:apply_tag).with("things")
    list.add_people [1]
    list.apply_tags!
  end

=begin
  it "adds people in batches of 100k", :vcr_off do
    list = NationBuilder::TemporaryList.create ["my tag"]
    list.stub(:nb_ids).and_return (1..100_001).to_a
    list.should_receive(:add_nb_people).with (1..100_000).to_a
    list.should_receive(:add_nb_people).with [100_001]
    list.add_people nil # does not matter for user_ids as we are stubbing
  end
=end
end
