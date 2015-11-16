class BlockedIp < ActiveRecord::Base
  validates :ip_address, format: { with: /\A(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\z/ }
  validates :ip_address, :uniqueness => true

  def to_s
    return ip_address
  end
end
