unless Rails.env.production?
  module Kernel
    def clear_tables
      [Blast, Push, Email, Page, UserActivityEvent, PageSequence, Campaign, Event, GetTogether, List].each do |table|
        puts table.inspect
        table.destroy_all
      end
    end
  end
end
