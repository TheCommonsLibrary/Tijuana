# encoding: utf-8

require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "../../lib/string_without_smartquotes")

describe String do

  it "replaces 'smart' double quotes with real ones" do
    '“smart double quotes”'.without_smartquotes.should == '"smart double quotes"'
  end

  it "replaces 'smart' single quotes with real ones" do
    "‘smart single quotes’".without_smartquotes.should == "'smart single quotes'"
  end

  it "leaves backticks untouched" do
    "`backtick`".without_smartquotes.should == "`backtick`"
  end

  it 'leaves real double quotes untouched' do
    '"real double quotes"'.without_smartquotes.should == '"real double quotes"'
  end

  it 'leaves real single quotes untouched' do
    "'real single quotes'".without_smartquotes.should == "'real single quotes'"
  end


end