module Api
  class ModelsController < ApplicationController

    skip_forgery_protection

    def index
      objects = ApsService.list_objects

      models = objects.map do |obj|
        {
          name: obj["objectKey"],
          urn: ApsService.urnify(obj["objectId"])
        }
      end

      render json: models
    end

    def create

      file = params["model-file"]

      return render plain: "File missing", status: 400 unless file

      result = ApsService.upload_object(
        file.original_filename,
        file.tempfile.path
      )

      urn = ApsService.urnify(result["objectId"])

      ApsService.translate_object(
        urn,
        params["model-zip-entrypoint"]
      )

      render json: {
        name: result["objectKey"],
        urn: urn
      }

    end

    def status

      manifest = ApsService.get_manifest(params[:id])

      if manifest.nil?
        render json: { status: "n/a" }
        return
      end

      render json: {
        status: manifest["status"],
        progress: manifest["progress"],
        messages: []
      }

    end

  end
end
