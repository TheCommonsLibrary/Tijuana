require 'csv'

class UserCsvFileReader
  def csv_rows_to_array(file)
    csv_rows = []
    CSV.foreach(file) { |row| csv_rows << row }
    csv_rows
  end
end