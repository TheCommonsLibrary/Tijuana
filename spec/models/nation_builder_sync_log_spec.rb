require 'spec_helper'

describe NationBuilderSyncLog do

  it "should handle utf 8 in the payload and data" do
    expect{ create(:nation_builder_sync_log, data: {"data" => 'διατ'}, payload: {"data" => 'διατ'}) }.to_not raise_error
  end

  it "should handle utf 8 4 byte chars in the payload and data" do
    expect{ create(:nation_builder_sync_log, data: {"data": 'foo𝌆bar'}, payload: {"data": 'foo𝌆bar'}) }.to_not raise_error
    expect(NationBuilderSyncLog.first.payload).to eq({"data" => "foobar"})
    expect(NationBuilderSyncLog.first.data).to eq({"data" => "foobar"})
  end
end
