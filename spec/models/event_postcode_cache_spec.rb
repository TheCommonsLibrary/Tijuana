require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe EventPostcodeCache do
  
  before(:each) do
    Rails.cache.clear
    @get_together = create(:get_together)
    @event = create(:event, :get_together => @get_together)
    @finder_call_count = 0
  end

  it "should call finder block once per postcode and cache result" do
    fetch("2000").should == @event
    @finder_call_count.should == 1
    fetch("2000").should == @event
    @finder_call_count.should == 1
  end

  it "should call finder block for each postcode" do
    fetch("2000")
    @finder_call_count.should == 1
    fetch("2010")
    @finder_call_count.should == 2
  end

  it "should cache nil if no matching event" do
    @event = nil
    fetch("2000").should == nil
    @finder_call_count.should == 1
    fetch("2000").should == nil
    @finder_call_count.should == 1
  end

  it "should raise exception with blank args" do
    expect { EventPostcodeCache.fetch(nil, "2010"){} }.to raise_exception(/Missing get together id/)
    expect { EventPostcodeCache.fetch(@get_together.id, ""){} }.to raise_exception(/Missing postcode/)
  end

  def fetch(postcode)
    EventPostcodeCache.fetch(@get_together.id, postcode) do
      @finder_call_count += 1
      @event
    end
  end

end
