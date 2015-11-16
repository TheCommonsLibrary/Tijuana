desc "send delayed mails to mps (page_id = 512 only)"
task :send => :environment  do
  puts "Starting to send delayed emails to mp"
  UserEmail.where("page_id = 512 and id < 160177").each do |useremail|
    success = useremail.send!
    puts "Failed to delay email #{useremail.id}: #{useremail.errors.first}" unless success
    puts "Successfully sent delayed email #{useremail.id}" if success
  end
end