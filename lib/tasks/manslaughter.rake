desc "Kills all the bloody cucumber processes. Needs to kill firefox as well"
task :manslaughter => :environment do
  firefox = %x[ps ax | grep firefox|grep -v "grep firefox"|cut -d ' ' -f 1]
  firefox.split("\n").each do |pid|
    `kill -9 #{pid}`
  end

  pids = %x[ps ax | grep cucumber|grep -v "grep cucumber"|cut -d ' ' -f 1]
  pids.split("\n").each do |pid|
    `kill -9 #{pid}`
  end

end
