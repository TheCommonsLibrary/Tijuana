require 'csv'

module ReportTable
  include ActionView::Helpers::NumberHelper
    
  def to_csv
    CSV.generate do |csv|
      csv << self.class.columns
      self.rows.each do |row|
        csv << row
      end
    end
  end
end