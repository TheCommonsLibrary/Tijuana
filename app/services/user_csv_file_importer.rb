class UserCsvFileImporter

  def initialize(uploaded_csv, params)
    @csv_rows = uploaded_csv
    @identifier = params['identifier']
    @preview = !!params['preview']
    @quarantine = !!params['quarantine']
    @send_welcome = !!params['welcome_email']
    @tags = params['tags']
  end

  def each
    user_ids = []
    @csv_rows.each_with_index do |row, i|
      if i==0
        @csv_rows[0][9] = 'result'
        yield "#{@csv_rows[0].join(',')}\n"
      else
        result = insert_or_update(row, user_ids)
        row[9] = result
        yield "#{row.join(',')}\n"
      end
    end
    AddTagsJob.add_tags user_ids, @tags if @tags.present? && user_ids.present?
    @csv_rows
  end

  private

  def send_welcome_email?(user)
    user && @send_welcome && !@preview && !@quarantine
  end

  def insert_or_update(row, user_ids)
    begin
      attributes = csv_row_to_attributes(row)
      user = find_user(row[0])
      result = ''
      if user.nil? && @identifier == 'email'
        user, result = insert_user(attributes, row)
        UserMailer.welcome_to_getup(user) if send_welcome_email?(user)
      else
        result = update_user(user, attributes)
      end
      user_ids << user.id unless @preview
    rescue Exception => e
      result = "Error: #{e.message}"
    ensure
      return result
    end
  end

  def insert_user(attributes, row)
    attributes['email'] = row[0]
    unless @preview
      user = User.new(attributes)
      user.save_with_source_info! nil,nil,nil,'csv_import'
      user.quarantine!(source: 'import') if @quarantine
    end
    return [user, 'New']
  end

  def update_user(user, attributes)
    user.attributes = attributes
    if user.changed?
      user.save! unless @preview
      return 'Update'
    else
      return 'No change'
    end
  end

  def find_user(value)
    if @identifier == 'email'
      return User.find_by_email(value)
    end
    if @identifier == 'id'
      return User.find(value)
    end
    if @identifier == 'token'
      decoded = EmailTrackingToken.decode(value)
      return User.find(decoded[:userid])
    end
  end

  def csv_row_to_attributes(row)
    attributes = {}
    attr_row_map = {1 => 'first_name',
                    2 => 'last_name',
                    3 => 'mobile_number',
                    4 => 'home_number',
                    5 => 'street_address',
                    6 => 'suburb',
                    7 => 'country_iso'}
    attr_row_map.each do |i, attr|
      unless row[i].try(:strip).blank?
        attributes[attr] = row[i].to_s
      end
    end
    postcode = Postcode.find_by_number(row[8])
    attributes['postcode_id'] = postcode.id unless postcode.nil?
    attributes
  end
end

class UserImportFailedException < StandardError
  def initialize(msg = 'User import failed.')
    super
  end
end
