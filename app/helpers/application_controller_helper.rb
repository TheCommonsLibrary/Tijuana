module ApplicationControllerHelper

  def set_payload_safe(hash, key, value, limit=299)
    hash[key] = value.try(:slice, 0, limit)
  end
end
