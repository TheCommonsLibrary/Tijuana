class NationBuilderSyncLog < ActiveRecord::Base
  self.table_name =  'nationbuilder_sync_logs'

  attr_accessible :source, :destination, :method, :endpoint, :data, :payload, :started_at, :completed_at, :user_id
  validates_presence_of :source, :destination, :endpoint, :started_at, :completed_at
  serialize :data, JSON
  serialize :payload, JSON
  belongs_to :user

  before_save do
    [:payload, :data].each do |attr|
      attr_text = read_attribute(attr)
      if attr_text.present?
        json = attr_text.to_json
        no_4byte_emojis = ''
        json.each_char{|c| no_4byte_emojis += c if c.bytes.count < 4 }
        self[attr] = JSON.parse(no_4byte_emojis) if no_4byte_emojis.length != json.length
      end
    end
  end
end
