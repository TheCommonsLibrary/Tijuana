require "google_drive"
require "csv"

class GoogleImporter
  attr_accessor :sheet

  def initialize
    session = GoogleDrive.saved_session("#{Rails.root}/config/google_drive.json")
    self.sheet = session.spreadsheet_by_key(AppConstants.election_google_sheet)
  end

  def import(worksheet)
    extract(sheet.worksheet_by_title(worksheet).rows)
  end

  def extract(rows)
    hashes = []
    csv_string = rows.map{|row| row.map(&:strip).join("|") }.join("\n")
    CSV.parse(csv_string, headers: true, col_sep: "|"){|row| hashes << row.to_hash}
    hashes.map{ |hash| hash.each_with_object({}) {|(k,v), h| k && h[k.downcase.gsub(/\s/,'_')] = v } }
  end
end
