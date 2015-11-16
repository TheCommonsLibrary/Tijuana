module ExceptionNotifier
  def self.rescue_and_mail_tech(env=nil, disable_session_section=false)
    yield
  rescue Exception => e
    begin
      return if IGNORED_EXCEPTIONS.include?(e.class.name)
      options = e.respond_to?(:record) ? {data: {record: e.record}} : {}
      if env
        add_sections_excluding_sessions!(env) if disable_session_section
        ExceptionNotifier.notify_exception(e, options.merge(env: env))
      else
        ExceptionNotifier.notify_exception(e, options)
      end
    rescue Exception => e
      Rails.logger.error("#{e.message}: Exception thrown delivering exception notification to Tech ")
    end
  end

  # some uses at the rack level do not yet have the required environment session variables set
  def self.add_sections_excluding_sessions!(env)
    sections = {sections: %w{request environment backtrace}}
    if env['exception_notifier.options'].present?
      env['exception_notifier.options'].merge(sections)
    else
      env['exception_notifier.options'] = sections
    end
  end
  private_class_method :add_sections_excluding_sessions!
end
