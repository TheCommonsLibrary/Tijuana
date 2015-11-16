class PageSequenceSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers
  attributes :title, :blurb, :cover_image, :url, :pillar_pin
  def cover_image
    object.options[:facebook_image].gsub('http://cdn.getup.org.au', 'https://d68ej2dhhub09.cloudfront.net')
  end
  def url
    url = page_url(object.campaign.friendly_id, object.friendly_id, object.pages.first.friendly_id)
    url.gsub('http://', 'https://')
  end
end
