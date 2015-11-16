require 'open3'
require 'socket'

desc 'check mysql replication status'
namespace :db do
  task :replication_check => :environment do
    begin
      r = ActiveRecord::Base.connection.execute("show slave status").each(as: :hash).first

      unless  r["Slave_IO_Running"] == "Yes" && r["Slave_SQL_Running"] == "Yes" &&
        r["Last_Errno"].to_i == 0 && r["Seconds_Behind_Master"].to_i < 300

        status = "*** STATUS ***\n" + r.to_a.collect { |i| "#{i[0]}: #{i[1]}\n" }.join
        subject = "MySQL Slave Replication Down on #{Socket.gethostname}"

        mail_error(subject, status)
      end
    rescue
      subject = "MySQL Slave Replication Down on #{Socket.gethostname}"
      status = "SLAVE IS NOT RUNNING"

      mail_error(subject, status)
    end
  end
end

def mail_error(subject, status)
  Open3.popen3("mail -s \"#{subject}\" tech-ops@getup.org.au") do |stdin, stdout, stderr|
    stdin.write(status)
  end
end
