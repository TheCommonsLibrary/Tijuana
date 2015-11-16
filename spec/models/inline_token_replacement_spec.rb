require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe InlineTokenReplacement do
  include InlineTokenReplacement
  
  it "does not replace tokens if values are not specified" do
    text = "{This} will not be {Replaced}."
    text = replace_tokens(text, {"Animal" => "Cat"})
    text = "{This} will not be {Replaced}."
  end
  
  it "replaces all occurences of a token within a block of text" do
    text = "{Animal}s are called {Animal} because they are a {Animal}"
    text = replace_tokens(text, {"Animal" => "Cat"})
    text.should == "Cats are called Cat because they are a Cat"
  end
  
  it "allows defaults to be specified for when no value is available" do
    text = "{Animal|Dog}s go {NOISE|Woof Woof}"
    text = replace_tokens(text, {"Animal" => "Cat", "NOISE" => ""})
    text.should == "Cats go Woof Woof"
  end
  
  it "can take a lambda in place of a value to allow HTML to be inserted" do
    text = "All {Animal} deserve to be emphasised"
    text = replace_tokens(text, "Animal" => lambda { |default| "<em>KITTENS</em>"} )
    text.should == "All <em>KITTENS</em> deserve to be emphasised"
  end
  
  it "passes the default value to a lambda if one is provided" do
    text = "{Animal|Walruses} should be in italics"
    text = replace_tokens(text, "Animal" => lambda { |default| "<i>#{default.upcase}</i>"} )
    text.should == "<i>WALRUSES</i> should be in italics"
  end
end
