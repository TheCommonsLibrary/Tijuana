class AskStatsTable
  include ReportTable

  def self.columns
    ["Created", "Page Sequence", "Page", "Tags", "Ask Type", "Actions Taken", "New Members", "Total $", "Avg. $"]
  end

  def initialize(stats)
    @stats = stats
    @pages = tagged_pages
  end

  def rows
    @stats.map{|stat| row_for(stat) }
  end

  private

  def row_for(stat)
    row = [
      stat.created_at.to_date.to_s,
      stat.page_sequence_name,
      stat.page_name,
      page_tags(stat.page_id),
      stat.type,
      stat.actions_taken.to_i,
      stat.subscriptions.to_i
    ]
    row += total_and_average_donations_columns(stat)
    row
  end

  def total_and_average_donations_columns(stat)
    total = Donation.total_by_content_module(stat.content_module_id)
    average = (total / stat.total_actions) if stat.total_actions.to_i > 0
    [total, average].map &method(:number_to_currency)
  end

  def tagged_pages
    pages_including_deleted = Page.unscoped
    pages_including_deleted.includes(:tags).where(id: @stats.map(&:page_id))
  end

  def page_tags(page_id)
    @pages.detect{|p| p.id == page_id }.tags.join(", ") # uses ActiveRecord cache
  end
end
