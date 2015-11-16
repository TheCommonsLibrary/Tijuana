require 'spec_helper'

describe Note do
  describe "#create_or_update" do
    it "should create a new note if no notes exits" do
      Note.count.should eql 0
      Note.create_or_update("I command thee!")

      Note.count.should eql 1
      Note.first.value.should eql "I command thee!"
    end

    it "should update an existing note" do
      Note.create(:value => "It's like a jungle sometimes")
      Note.count.should eql 1

      Note.create_or_update("Welcome to the Jungle!")
      Note.count.should eql 1
      Note.first.value.should eql "Welcome to the Jungle!"
    end
  end
end
