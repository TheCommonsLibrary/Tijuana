module PerformanceHelper
  def perf_trace(context, &block)
    lines = block.source.split "\n"
    lines.shift
    lines.pop
  
    lines.each do |line|
      print line.yellow
      if line =~ /^\s*#/ || line =~ /^\s*$/
        puts ""
        next
      end
      start_time = Time.now
    
      begin
        context.eval line
      ensure
        seconds = (Time.now-start_time)
        puts " #{seconds.round(2).to_s}s".send(seconds > 3 ? :red : :cyan)
      end
    end
  end
end

RSpec.configuration.include PerformanceHelper, :type => :feature