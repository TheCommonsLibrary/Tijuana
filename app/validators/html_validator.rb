module HtmlValidator
  include W3CValidators

  def self.validate_each(record, attribute, value)
    #if service_available?
    validator = MarkupValidator.new
    validator.set_doctype!(:html4)
    doc = <<DOC
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"><html><head><title></title></head><body><div>#{value}</div></body></html>
DOC
    results = nil
    success = false
    3.times do
      begin
        results = validator.validate_text(doc)
        success = true
        break
      rescue Exception => e
        errors = ["Net::HTTPFatalError", "Timeout::Error", "Errno::ECONNREFUSED", "Errno::ETIMEDOUT"]
        raise e if !errors.include?(e.class.name)
      end
    end

    if success
      if results.errors.length > 0
        results.errors.each do |err|
          record.errors.add(attribute, "^" + err.to_s.gsub("ERROR; URI: upload://Form Submission; ", ""))
        end
      end
    else
      record.errors.add(attribute, ": Could not validate content. Please try again.")
    end

    success
  end
end
