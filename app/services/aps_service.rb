require 'net/http'
require 'json'
require 'base64'

class ApsService

  CLIENT_ID     = ENV["APS_CLIENT_ID"]
  CLIENT_SECRET = ENV["APS_CLIENT_SECRET"]
  BUCKET = ENV["APS_BUCKET"] || "#{CLIENT_ID.downcase}-basic-app"

  class << self

    def internal_token

      uri = URI(
        "https://developer.api.autodesk.com/authentication/v2/token"
      )

      req = Net::HTTP::Post.new(uri)

      req.set_form_data(
        grant_type: "client_credentials",
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        scope: "data:read data:create data:write bucket:create bucket:read"
      )

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) do |http|
        http.request(req)
      end

      JSON.parse(response.body)["access_token"]

    end

    def viewer_token

      uri = URI(
        "https://developer.api.autodesk.com/authentication/v2/token"
      )

      req = Net::HTTP::Post.new(uri)

      req.set_form_data(
        grant_type: "client_credentials",
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        scope: "viewables:read"
      )

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) do |http|
        http.request(req)
      end

      JSON.parse(response.body)

    end

    def ensure_bucket
      token = internal_token

      uri = URI(
        "https://developer.api.autodesk.com/oss/v2/buckets/#{BUCKET}/details"
      )

      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{token}"

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) { |http| http.request(req) }

      return if response.code == "200"

      create_bucket(token)
    end

    def create_bucket(token)

      uri = URI(
        "https://developer.api.autodesk.com/oss/v2/buckets"
      )

      req = Net::HTTP::Post.new(uri)

      req["Authorization"] = "Bearer #{token}"
      req["Content-Type"] = "application/json"

      req.body = {
        bucketKey: BUCKET,
        policyKey: "persistent"
      }.to_json

      Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) { |http| http.request(req) }

    end

    def list_objects

      ensure_bucket

      token = internal_token

      uri = URI(
        "https://developer.api.autodesk.com/oss/v2/buckets/#{BUCKET}/objects"
      )

      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{token}"

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) { |http| http.request(req) }

      JSON.parse(response.body)["items"] || []

    end

    def upload_object(name, file_path)

      ensure_bucket

      token = internal_token

      uri = URI(
        "https://developer.api.autodesk.com/oss/v2/buckets/#{BUCKET}/objects/#{name}"
      )

      req = Net::HTTP::Put.new(uri)

      req["Authorization"] = "Bearer #{token}"

      req.body = File.binread(file_path)

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) { |http| http.request(req) }

      JSON.parse(response.body)

    end

    def translate_object(urn, root_filename=nil)

      token = internal_token

      uri = URI(
        "https://developer.api.autodesk.com/modelderivative/v2/designdata/job"
      )

      req = Net::HTTP::Post.new(uri)

      req["Authorization"] = "Bearer #{token}"
      req["Content-Type"] = "application/json"

      req.body = {
        input: {
          urn: urn,
          compressedUrn: !root_filename.nil?,
          rootFilename: root_filename
        },
        output: {
          formats: [
            {
              type: "svf2",
              views: ["2d", "3d"]
            }
          ]
        }
      }.to_json

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) { |http| http.request(req) }

      JSON.parse(response.body)

    end

    def get_manifest(urn)

      token = internal_token

      uri = URI(
        "https://developer.api.autodesk.com/modelderivative/v2/designdata/#{urn}/manifest"
      )

      req = Net::HTTP::Get.new(uri)

      req["Authorization"] = "Bearer #{token}"

      response = Net::HTTP.start(
        uri.hostname,
        uri.port,
        use_ssl: true
      ) { |http| http.request(req) }

      return nil if response.code == "404"

      JSON.parse(response.body)

    end

    def urnify(id)
      Base64.strict_encode64(id).delete("=")
    end

  end

end
