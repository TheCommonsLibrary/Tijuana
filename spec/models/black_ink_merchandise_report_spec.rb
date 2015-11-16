require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe BlackInkMerchandiseReport do
  def create_merch_module
    @postcode = create(:postcode)
    @user = create(  :user,
                      first_name: 'John',
                      last_name: 'Smith',
                      street_address: '1 example street',
                      suburb: 'Sydney',
                      postcode: @postcode,
                      mobile_number: '',
                      home_number: '02 9999 9999'
    )
    @merch_module_with_item = create(:merch_module)
    form_fields = [{name: 'item'}]
    @merch_module_with_item.options = @merch_module_with_item.options.merge(custom_fields: {form_fields: form_fields})
    @merch_module_with_item.save!
  end

  private :create_merch_module

  def create_donation(amount_in_dollars, item)
    date = DateTime.now
    donation = create(:donation, amount_in_cents: 100*amount_in_dollars, content_module: @merch_module_with_item, user: @user, item: item, created_at: date)
    donation.transactions << create(:transaction, donation: donation, successful: true, refunded: false, created_at: date)
    donation
  end

  private :create_donation

  before :each do
    create_merch_module
    Timecop.freeze(DateTime.parse('2013-06-11 16:00:26 +1000')) do
      @donation1 = create_donation(50, "'2'")
      @donation2 = create_donation(20, "'1'")
    end
  end

  describe '#to_csv' do
    it 'includes correctly formatted header row' do
      csv = BlackInkMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv
      csv_lines = csv.split("\n")
      csv_lines[0].should == 'quantity_of_books,first_name,surname,address,suburb,state,postcode,email,phone_number'
    end

    it 'reports on donation in specified format' do
      csv = BlackInkMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv
      csv_lines = csv.split("\n")
      csv_lines[1].should == "2,#{@user.first_name},#{@user.last_name},#{@user.street_address},#{@user.suburb},#{@postcode.state},#{@postcode.number},#{@user.email},#{@user.home_number}"
    end

    it 'does not include refunded donations in report' do
      @donation1.transactions.first.refund!(50)
      @donation2.transactions.first.refund!(10)
      csv = BlackInkMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv
      csv.split("\n").count.should == 1
    end

    it 'does not include any items where the item key starts with NONE' do
      create_merch_module
      donation = create_donation(50, 'NONE')
      csv = BlackInkMerchandiseReport.new(donation.content_module_id).to_csv
      csv.split("\n").count.should == 1
    end

  end

  describe '#mark_as_reported' do
    it 'marks donations as REPORT_GENERATED when they have been included in a report' do
      BlackInkMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).mark_as_reported
      @donation1.reload
      @donation2.reload
      @donation1.process_status.should == 'REPORT_GENERATED'
      @donation2.process_status.should == 'REPORT_GENERATED'
    end

    it 'does not include transaction in report when it has been marked REPORT_GENERATED' do
      BlackInkMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).mark_as_reported
      csv = BlackInkMerchandiseReport.new(@donation1.content_module_id, @donation2.content_module_id).to_csv
      csv.split("\n").count.should == 1
    end
  end

  describe 'contact number' do
    it 'should include the mobile number and not the home phone' do
      @user.mobile_number = '0411111111'
      @user.save
      csv = BlackInkMerchandiseReport.new(@donation1.content_module_id).to_csv
      csv_lines = csv.split("\n")
      csv_lines[1].should include "#{@user.mobile_number}"
      csv_lines[1].should_not include "#{@user.home_number}"
    end
  end
end
