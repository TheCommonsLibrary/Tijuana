require 'csv'

class MergeUploader
  def self.create_merge_records?(merge, upload_file)
    unless upload_file
      merge.errors.add(:base, "Merge File required") 
      return false
    end

    headers = nil
    CSV.open(upload_file.path, 'rb', {:headers => true, :return_headers => true}).each_with_index do |row, index|
      if index == 0
        headers = get_headers(merge, row)
        return false if headers == nil
      else
        headers.each do |elem|
          header = elem[0]
          merge.errors.add(:base, "Merge headers cannot contain braces or vertical bars: #{header}") if header.match(/[\{|\||\}]/)
          merge_record = MergeRecord.create(name: header.strip, value: row[header], merge: merge, join_id: row[merge.join_field_name])
          merge.errors.add(:base, "Unable to create merge record: #{merge_record.errors.full_messages}") unless merge_record.valid?
        end
      end
    end
    merge.errors.empty?
  end

private

  def self.get_headers(merge, row)
    unless row.detect {|h| h[0] == merge.join_field_name}
      merge.errors.add(:join_field_name, "Unable to find matching header") 
      return nil
    end
    if row.length == 0
      merge.errors.add(:base, "No headers found in CSV file")
      return nil
    end
    row.select {|h| h[0].present? }
  end
end
