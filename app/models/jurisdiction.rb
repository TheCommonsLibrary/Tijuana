class Jurisdiction < ActiveRecord::Base
  has_many :parties
  has_many :electorates
  has_many :regions

  extend RemoveIdProtection

  validates :code, :uniqueness => true
  validates :name, :uniqueness => true

  def self.select_options_for_states
    Jurisdiction.all.reject { |item| item.code == "FEDERAL"}.map {|item| [item.name, item.code]}
  end

  def self.select_options_for_federal
    Jurisdiction.all.select { |item| item.code == "FEDERAL"}.map {|item| [item.name, item.code]}
  end

  def self.select_options
    Jurisdiction.all.map {|item| [item.name, item.code]}
  end

  def federal?
    code == "FEDERAL"
  end

  alias_attribute :to_s, :code
end
