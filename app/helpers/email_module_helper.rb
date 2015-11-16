module EmailModuleHelper

  def self.subject_placeholder(content_module)
    if content_module.prompt_as_placeholder?
      content_module.default_subject
    else
      "Enter your personalised subject"
    end
  end

  def self.body_placeholder(content_module)
    if content_module.prompt_as_placeholder?
      content_module.default_body
    else
      "Enter your personalised message here"
    end
  end
end
