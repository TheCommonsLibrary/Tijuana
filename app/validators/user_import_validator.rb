class UserImportValidator
  def initialize(uploaded_csv_rows)
    @template = AppConstants.user_import_csv_headers.split(',')
    @uploaded_csv_rows = uploaded_csv_rows
  end

  def validate!
    if @uploaded_csv_rows.any? && @uploaded_csv_rows.size <= 1
      raise UserImportInvalidContentException
    end
    if @uploaded_csv_rows.size > 1
      check_file_structure!
      check_for_null_strings
    end
  end

  private

  def check_file_structure!
    if valid_headers? == false
      raise UserImportInvalidHeadersException
    end
    @uploaded_csv_rows.each do |r|
      raise UserImportInvalidContentException unless r.size.between?(@template.size,@template.size+1)
    end
  end

  def check_for_null_strings
    @uploaded_csv_rows.each do |row|
      row.each do |cell|
        raise UserImportNullString if cell && cell.match(/^\s*null\s*$/i)
      end
    end
  end

  def valid_headers?
    for i in 0..(@template.size-1) do
      return false if @template[i] != @uploaded_csv_rows[0][i]
    end
    return true
  end
end

class UserImportInvalidContentException < StandardError
  def initialize(msg = 'Invalid CSV content.')
    super
  end
end

class UserImportInvalidHeadersException < StandardError
  def initialize(msg = 'Invalid CSV headers, please refer to the template file.')
    super
  end
end

class UserImportNullString < StandardError
  def initialize(msg = 'CSV cannot contain NULL strings. Fields must be blank.')
    super
  end
end
