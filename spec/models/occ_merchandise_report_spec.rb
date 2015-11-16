require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe OccMerchandiseReport do
  def create_donation_module
    @user = create(:user, postcode: create(:postcode))
    @donation_module_with_item_and_size = create(:donation_module)
    item_mapping = {
      'item1-size1' => {sku: 'SKU1', title: 'ITEMTITLE1', weight: 'ITEMWEIGHT1'},
      'item2-size2' => {sku: 'SKU2', title: 'ITEMTITLE2', weight: 'ITEMWEIGHT2'},
    }
    form_fields = [{name: 'item'}, {name: 'size'}]
    @donation_module_with_item_and_size.options = @donation_module_with_item_and_size.options.merge(custom_fields: {form_fields: form_fields, item_mapping: item_mapping})
    @donation_module_with_item_and_size.save!
  end

  private :create_donation_module

  def create_donation(amount_in_dollars, item, size)
    date = DateTime.now
    donation = create(:donation, amount_in_cents: 100*amount_in_dollars, content_module: @donation_module_with_item_and_size, user: @user, item: item, size: size, created_at: date)
    donation.transactions << create(:transaction, donation: donation, successful: true, refunded: false, created_at: date)
    donation
  end

  private :create_donation

  before :each do
    create_donation_module
    Timecop.freeze(DateTime.parse("2013-06-11 16:00:26 +1000")) do
      @donation1 = create_donation(50, 'item1-', 'size1')
      @donation2 = create_donation(20, 'item2-', 'size2')
    end
  end

  describe "to_csv" do
    it "reports on donation in specified format, alternating ORDER and ITEM" do
      csv = OccMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv
      csv_lines = csv.split("\n")
      csv_lines[0].should start_with "ORDER,GETUP#{@donation1.id}"
      csv_lines[1].should start_with "ITEM,GETUP#{@donation1.id}"
      csv_lines[2].should start_with "ORDER,GETUP#{@donation2.id}"
      csv_lines[3].should start_with "ITEM,GETUP#{@donation2.id}"
    end

    it "looks up sku, title and weight in item_mapping" do
      csv = OccMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv
      csv_lines = csv.split("\n")
      csv_lines[1].should start_with "ITEM,GETUP#{@donation1.id},SKU1,ITEMTITLE1,50.0,1,ITEMWEIGHT1"
      csv_lines[3].should start_with "ITEM,GETUP#{@donation2.id},SKU2,ITEMTITLE2,20.0,1,ITEMWEIGHT2"
    end

    it "has specified date format" do
      csv = OccMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv
      csv_lines = csv.split("\n")
      csv_lines[0].should match /,11\/06\/2013 16:00:26,/
    end

    it "does not include refunded donations in report" do
      @donation1.transactions.first.refund!(50)
      @donation2.transactions.first.refund!(10)
      OccMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv.should == ""
    end

    it "does not include any items where the item key starts with NONE!" do
      create_donation_module #this ensures the next donation is part of its own module
      donation = create_donation(50, 'NONE', 'anything')
      OccMerchandiseReport.new(donation.content_module_id).to_csv.should == ""
    end

  end

  describe "mark_as_reported" do
      it "marks donations as REPORT_GENERATED when they have been included in a report" do
      OccMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).mark_as_reported
      @donation1.reload
      @donation2.reload
      @donation1.process_status.should == 'REPORT_GENERATED'
      @donation2.process_status.should == 'REPORT_GENERATED'
      end

    it "does not include transaction in report when it has been marked REPORT_GENERATED" do
      OccMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).mark_as_reported
      OccMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv.should == ""
    end
  end
end
