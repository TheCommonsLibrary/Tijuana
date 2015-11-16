require 'base64'
require 'json'

USAGE = "Usage: rake 'pixel[pixel-name,context-of-pixel]'"

desc "Generate a new GetUp Pixel. #{USAGE}"
task :pixel, [:name, :context] do |t, args|
  name = args[:name]
  context = args[:context]
  if name.nil? || context.nil?
    puts "Invalid arguments. #{USAGE}"
    next #return from this task
  end

  puts "\n<!-- GetUp pixel - name: '#{name}', context: '#{context}' -->\n<img src=\"https://www.getup.org.au/event/#{Base64.encode64({name: name, context: context}.to_json).gsub(/\n/,'')}/beacon.gif\" /> \n\n"
end
