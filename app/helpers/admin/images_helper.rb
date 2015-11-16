module Admin
  module ImagesHelper
    def responsive_image(image)
      "height:auto;max-width:#{ image.image_width }px;width:100%;"
    end

    def token_image_url(image, format = :original)
      "http://#{S3[:token_cdn_host]}/#{image.name(format)}"
    end

    def hosted_image_tag(image, params = {}, use_real_cdn=true)
      params[:alt] = image.image_description if image.image_description
      url = token_image_url(image, :full)
      url = substitute_real_cdn_url(url) if use_real_cdn
      image_tag(url, params)
    end

    def image_info(image)
      info = { "Image URL" => token_image_url(image, :full),
        "Original URL" => token_image_url(image, :original),
        "Thumbnail URL" => token_image_url(image, :thumbnail),
        "Image type" => image.image_content_type,
        "File Size" => "#{number_to_human_size(image.image_file_size) } (#{image.image_file_size } bytes)" }
      if image.image_width
        info["Dimensions"] = "#{ image.image_width } x #{ image.image_height } pixels (width x height)" 
      end
      info
    end
  end
end
