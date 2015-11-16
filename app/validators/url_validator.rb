class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    URI.parse(value)
  rescue URI::InvalidURIError
    record.errors.add(attribute, $!.message, :value => value)
  end
end
