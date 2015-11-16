require "hashids"

describe "Hashids Algorithm doesn't change when we update the gem" do  
  let(:salt) { "NqJqY1p40XYWXvvvDvwItX7GtVXqcp" }
  let(:min_hash_length) { 0 }
  let(:alphabet) { ([*'0'..'9',*'A'..'Z',*'a'..'z'] - ['d']).join }
  let(:hashids) { Hashids.new(salt, min_hash_length, alphabet) }

  it "encodes as we expect" do
    hashids.encode(934285, 29356345).should eq("mX5kNI28VGq")
  end

  it "decodes as we expect" do
    hashids.decode("mnQJaCBKEWQ").should eq([756489, 8765933])
  end
end
