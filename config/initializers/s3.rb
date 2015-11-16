S3 = {
  enabled: !!ENV['S3_KEY'],
  key: ENV['S3_KEY'],
  secret: ENV['S3_SECRET'],
  bucket: ENV['S3_BUCKET'],
  cdn_host: ENV['S3_CDN_HOST'],
  token_cdn_host: ENV['S3_TOKEN_CDN_HOST'],
}

if S3[:enabled]
  Rails.logger.info "Configured for Amazon S3 with key #{S3[:key]} and bucket #{S3[:bucket]}"
else
  Rails.logger.warn "Disabling Amazon S3 integration; falling back to local storage."
end
