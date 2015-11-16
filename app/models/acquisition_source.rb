class AcquisitionSource < ActiveRecord::Base
  settable_fields = [:content, :medium, :name, :slug, :source, :user_id, :generated]
  attr_accessible(*settable_fields)
  validates_presence_of :medium, :name, :slug, :source, :content
  validates_format_of :name, without: /[^\u0000-\u007F]+/, message: 'should not have smart quotes, long dashes or any other unusual characters'
  belongs_to :page
  belongs_to :user
  validates_uniqueness_of :name, scope: [:source, :medium, :content, :generated], message: 'already exists with this combination of source, medium and version'

  def self.options_for_source
    [['Facebook', 'fb'], ['Microsite', 'ms'], ['Google Ads', 'ga'], ['Media Story', 'md'], ['Twitter', 'tw'], ['Instagram', 'in'], ['Website', 'we'], ['Community Run', 'cr']]
  end

  def self.options_for_medium
    [['Organic', 'org'], ['Cost Per Click', 'cpc'], ['Cost Per Impression', 'cpm'], ['Search Ad', 'sea'], ['Display Ad', 'dis']]
  end

  def self.options_for_content
    4.times.map{|i| ["Version #{i+1}", "v#{i+1}"]}
  end

  # implement source_label, medium_label etc
  def method_missing(method_sym)
    match = method_sym.to_s.match(/(.*)_label/)
    field = match && match[1]
    super unless field && respond_to?(field)
    option = self.class.send(:"options_for_#{field}").detect{|opt| opt.last == self[field] }
    option && option.first
  end

  private

  before_validation do
    sanitised_name = name.downcase.gsub(/[ ]/, '_').gsub(/[^_0-9a-z]/, '') if name
    self.content ||= 'v1'
    self.slug = [source, medium, sanitised_name, content].join('-')
  end
end
