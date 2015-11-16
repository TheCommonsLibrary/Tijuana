Given /^I have (\d+) (?:fixture )?images?$/ do |n|
  Image.delete_all
  filename = File.join(Rails.root, 'spec/fixtures/images/wikileaks.jpg')
  n.to_i.times { Image.create(:image_file_name => filename) }
end

When /^I upload a fixture image file$/ do
  filename = File.join(Rails.root, 'spec/fixtures/images/wikileaks.jpg')
  attach_file(:image_image, filename)
end

Given /^I have (\d+) (?:fixture )?downloadable assets?$/ do |n|
  DownloadableAsset.delete_all
  filename = File.join(Rails.root, 'spec/fixtures/images/wikileaks.jpg')
  n.to_i.times { DownloadableAsset.create!(:asset_file_name => filename, :link_text => "Wikileaks file") }
end

When /^I upload a fixture downloadable asset$/ do
  filename = File.join(Rails.root, 'spec/fixtures/images/wikileaks.jpg')
  step %{I fill in "asset_link_text" with "Wikileaks file"}
  attach_file(:asset_asset, filename)
end

