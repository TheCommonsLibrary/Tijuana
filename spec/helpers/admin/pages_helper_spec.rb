require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::PagesHelper do
  it "should link to the images module" do
    expected = %Q{<a class="add-module-link images_module" target="_blank" href="/admin/images">lorem ipsum</a>}
    external_module_link(Image, "lorem ipsum").should eql(expected)
  end
end
