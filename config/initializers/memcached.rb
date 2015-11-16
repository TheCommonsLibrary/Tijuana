servers = (ENV["MEMCACHIER_SERVERS"] || "").split(",")
options = {
  username: ENV["MEMCACHIER_USERNAME"],
  password: ENV["MEMCACHIER_PASSWORD"],
  failover: true,
  socket_timeout: 1.5,
  socket_failure_delay: 0.2,
  down_retry_delay: 60,
  pool_size: ENV['RAILS_MAX_THREADS'] || 5,
}

if ENV["MEMCACHIER_SERVERS"].present?
  Rails.application.config.cache_store = :dalli_store, servers, options
end
