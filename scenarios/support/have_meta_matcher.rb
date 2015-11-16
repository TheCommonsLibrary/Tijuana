RSpec::Matchers.define :have_meta do |name, expected|
  match do |actual|
    if expected.kind_of?(Regexp)
      find(%{meta[property="#{name}"]}, :visible => false)['Content'].should =~ expected
    else
      has_css?(%{meta[property="#{name}"][content="#{expected}"]}, :visible => false)
    end
  end

  failure_message_for_should do |actual|
    actual = first("meta[name='#{name}']")
    if actual
      "expected that meta #{name} would have content='#{expected}' but was '#{actual[:content]}'"
    else
      "expected that meta #{name} would exist with content='#{expected}'"
    end
  end
end