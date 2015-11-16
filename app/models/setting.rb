class Setting < ActiveRecord::Base
  def self.gateway1_percentage
    self["gateway1_percentage"].present? ? Integer(self["gateway1_percentage"]) : 100
  end

  def self.[](key)
    setting = Rails.cache.fetch("setting.#{key}") do
      Setting.find_by_key(key)
    end
    setting.nil? ? nil : setting.value
  end

  def self.[]=(key, value)
    Rails.cache.delete("setting.#{key}")
    setting = Setting.find_by_key(key)
    if setting.nil?
      setting = Setting.new(key: key, value: value)
      setting.save!
    else
      setting.update_attributes!(:value => value)
    end
  end

  def self.has_key?(key)
    Setting.find_by_key(key).nil?
  end

  def self.quarantined_controlshift_slugs
    (self[:quarantined_controlshift_slugs] || '').split(/,/)
  end

  def self.quarantined_controlshift_slugs=(slugs)
    self[:quarantined_controlshift_slugs] = (slugs || []).join(',')
  end

  def self.enabled?(key)
    self[key] == '1'
  end
end
