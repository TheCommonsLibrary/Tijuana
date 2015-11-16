require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Image do
  before do
    @fixure_file = File.new(Rails.root + 'spec/fixtures/images/wikileaks.jpg')
  end
  it "validates presence of images" do
    img = Image.new(:image => File.new(Rails.root + 'spec/fixtures/images/wikileaks.jpg'))
    img.should be_valid

    img = Image.new()
    img.should_not be_valid
  end

  describe "searching" do
    before do
      Image.delete_all
      create(:image, :created_at => 10.months.ago)
      5.times do |min|
         create(:image, :created_at =>  min.minutes.ago)
      end
    end

    it "finds the latest" do
      Image.all.size.should eql(6)
      Image.latest(5).to_a.size.should eql(5)
      Image.latest(5).all { |x| x.created_at > 10.minutes.ago }.should be_truthy
    end
  end

  describe "names" do
    before(:all) do
      @image = Image.create(image: File.new(Rails.root + 'spec/fixtures/images/wikileaks.jpg'))
    end
    it "correctly formulates original name" do
      @image.name.should eql("image_#{@image.id}_original.jpg")
    end
    it "correctly formulates thumbnail name" do
      @image.name(:thumbnail).should eql("image_#{@image.id}_thumbnail.jpg")
    end
    after(:all) do
      Image.delete_all
    end
  end

end
