module Requestbin

    BASE_URL = "http://requestb.in/api/"
    API_VERSION = "v1"

    class Bins

        def self.create
            post_request('bins')
        end

        def self.get(bin_name)
            get_request(File.join('bins', bin_name.to_s))
        end

        def self.requests(bin_name)
            get_request(File.join('bins', bin_name.to_s, 'requests'))
        end

        def self.request(bin_name, request_name)
            get_request(File.join('bins', bin_name.to_s, 'requests', request_name.to_s))
        end

        private

        def self.post_request(route)
          request('POST', route)
        end

        def self.get_request(route)
            request('GET', route)
        end


        def self.request(method, route)
          path = path_for(route)
          uri = uri_for(path)
          method = method.upcase
          headers = header()
          res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
            case method
            when 'POST'   then request = Net::HTTP::Post.new(uri.request_uri, headers)
            when 'GET'    then request = Net::HTTP::Get.new(uri.request_uri, headers)
            else
              return {}
            end
            http.request request
          end
          parse_response(res)
        end

        def self.parse_response(response)
            begin
                JSON.parse(response.body)
            rescue JSON::ParserError => e
                response.body.is_a?(Array) ? response.body : {' ErrorCode' => -1 }
            end
        end

        def self.path_for(route)
            File.join('', API_VERSION, route.to_s)
        end

        def self.uri_for(path)
            URI(File.join(BASE_URL, path))
        end

        def self.header
            { 'Content-Type' => 'application/json' }
        end
    end
end