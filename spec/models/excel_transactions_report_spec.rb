require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ExcelTransactionsReport do

  HEADER_ROW = "Donation ID,Txn ID,Member ID,Member Email,Txn Status,Amount,Txn Date,Settlement Date,Payment Method,Cheque Number,Cheque Name,Cheque Bank,Cheque Branch,Cheque BSB,Cheque Account Number,Frequency,Campaign,Page Sequence,Page"

  it "should create report from special filter by relation" do
    page = create(:page_with_parent)
    donation1 = create(:donation, amount_in_cents: 1000, frequency: "Weekly", page: page, payment_method: 'paypal')
    transaction1_1 = create(:transaction, donation: donation1, amount_in_cents: 1100, successful: true,  created_at: DateTime.parse("2013-05-24 16:03:11 +1000"), settled_on: Date.parse('2013-05-25'))
    transaction1_2 = create(:transaction, donation: donation1, amount_in_cents: 1200, successful: false, created_at: DateTime.parse("2013-05-24 16:03:12 +1000"))
    donation2 = create(:donation, amount_in_cents: 2000, frequency: "Weekly", page: page, payment_method: 'credit_card', card_number: '4111111111111111')
    transaction2_1 = create(:transaction, donation: donation2, amount_in_cents: 2100, created_at: DateTime.parse("2013-05-24 16:03:21 +1000"))
    relation = Transaction.filter_by({})
    report = ExcelTransactionsReport.new(relation)
    csv_rows = report.to_csv.split("\n")
    csv_rows[0].should == HEADER_ROW
    csv_rows[1].should == %Q{#{donation2.id},#{transaction2_1.id},#{donation2.user.id},#{donation2.user.email},Successful,$21.00,2013-05-24 16:03:21 +1000,,Visa,,,,,,,Weekly,Dummy Campaign Name,Dummy Page Sequence Name,Unnamed Page}
    csv_rows[2].should == %Q{#{donation1.id},#{transaction1_2.id},#{donation1.user.id},#{donation1.user.email},Failed,$12.00,2013-05-24 16:03:12 +1000,,Paypal,,,,,,,Weekly,Dummy Campaign Name,Dummy Page Sequence Name,Unnamed Page}
    csv_rows[3].should == %Q{#{donation1.id},#{transaction1_1.id},#{donation1.user.id},#{donation1.user.email},Successful,$11.00,2013-05-24 16:03:11 +1000,2013-05-25,Paypal,,,,,,,Weekly,Dummy Campaign Name,Dummy Page Sequence Name,Unnamed Page}
  end

  describe "faster_number_to_currency" do
    it "formats as dollars" do
      relation = Transaction.filter_by({})
      report = ExcelTransactionsReport.new(relation)
      report.send(:faster_number_to_currency, 5000).should == "$50.00"
      report.send(:faster_number_to_currency, 5050).should == "$50.50"
      report.send(:faster_number_to_currency, 5051).should == "$50.51"
      report.send(:faster_number_to_currency, 51).should == "$0.51"
      report.send(:faster_number_to_currency, nil).should == ""
    end
  end

  describe "faster_titlecase" do
    it "capitalizes initial letters" do
      relation = Transaction.filter_by({})
      report = ExcelTransactionsReport.new(relation)
      report.send(:faster_titlecase, "weekly").should == "Weekly"
      report.send(:faster_titlecase, "one_off").should == "One Off"
    end
  end

end
