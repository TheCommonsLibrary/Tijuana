require 'csv'

desc "read from csv and take action on the given email target module"
task :take_action_on_email_target_from_csv, [:page_id, :csv_file] => :environment do |t, args|
  SUBJECT = "Submission to 2016 Federal Election inquiry"

  page = Page.find args[:page_id]
  raise 'Unable to identify page' unless page
  ask = page.ask_module
  raise 'Unable to identify content module' unless ask && ask.is_a?(EmailTargetsModule)

  CSV.foreach(args[:csv_file], :headers => true) do |row|
    ask = ContentModule.find ask.id #reload to ensure each action is recorded separately
    user = User.find_by_email row['Email']
    puts "Read user: #{row['Email']}"
    unless user
      user = User.create!(email: row['Email'], suburb: row['Suburb'], is_member: false)
      puts "Created user (not memeber): #{user.email}"
    end
    body = row['Submission']
    ask.update_user_email_attributes({subject: SUBJECT, body: body})
    begin
      ask.take_action(user, page)
    rescue DuplicateActionTakenError
      puts "skipped. action already taken for: #{row['Email']}"
    end
  end
end
