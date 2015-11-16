FactoryGirl.define do
  factory(:sent_email) do |e|
    e.subject           { 'subject line' }
    e.body              { "Dear {NAME|Friend},\n Thanks for all that you do.\n GetUp." }
    e.recipient_count   { 1 }
    e.sql               { 'select * from users where is_member = true and deleted_at is not null' }
  end
end
