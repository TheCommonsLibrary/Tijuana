# Expected CSV format: first_name, last_name, email, mobile_number/phone_number, postcode
class SignatureImporter
  def import(file_path, page, petition_module)
    signatures_created = 0
    CSV.open(file_path, 'r').each do |row|
      next if row[2].blank? #email
      begin
        user_details = {'first_name' => row[0], 'last_name' => row[1], 'email' => row[2], 'postcode_number' => row[4]}
        set_contact_number(user_details, row[3])
        user = find_or_instantiate_new_user(user_details)
        user_details['is_member'] = '0' if user.new_record?
        user_details_valid = user.validate_and_always_save_email(page.required_user_details, user_details, page, petition_module, nil)
        res = user_details_valid && petition_module.take_action(user, page)
        if res == false
          puts "Unable to save signature for: #{row[2]}" 
        else
          signatures_created = signatures_created + 1
        end
        petition_module = ContentModule.find(petition_module.id)
      rescue DuplicateActionTakenError
        puts "Ignored duplicate action from: #{row[2]}"
      rescue Exception => e
        puts "Failed to import: #{row[0]}, #{row[1]}, #{row[2]}, #{row[3]}, #{row[4]}. #{e}"
      end
    end
    puts "Added #{signatures_created} signatures!"
  end

  def identify_user(email)
    return nil if email.blank?
    addr = email.strip
    user = User.find_by_email(addr)
    user ||= User.new(:email => email)
    user
  end

  def find_or_instantiate_new_user(user_details)
    email = user_details['email']
    user = identify_user(email)
    puts user.new_record? ? "Created: #{email}" : "Updated: #{email}"
    user
  end

  def set_contact_number(user_details, contact_number)
    return if contact_number.blank?
    if contact_number.starts_with?('04') || (contact_number.starts_with?('4') && contact_number.strip.size == 9) 
      user_details['mobile_number'] = contact_number 
    else
      user_details['home_number'] = contact_number
    end
  end
end
