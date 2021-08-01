require_relative '../model'

module Spaceship
  class ConnectAPI
    class AppClip
      include Spaceship::ConnectAPI::Model

      attr_accessor :bundle_id

      attr_mapping(
        'bundleId' => 'bundle_id'
      )

      def self.type
        'appClips'
      end

      def get_app_clip_versions(client: nil, filter: {}, includes: nil, limit: nil, sort: nil)
        client ||= Spaceship::ConnectAPI
        resps = client.get_app_clip_versions(app_clip_id: id, filter: filter, includes: includes, limit: limit, sort: sort).all_pages
        resps.flat_map(&:to_models)
      end

      def create_app_clip_version(client: nil, app_store_version_id:, attributes:)
        client ||= Spaceship::ConnectAPI
        resp = client.post_app_clip_version(app_store_version_id: app_store_version_id, app_clip_id: id, attributes: attributes)
        return resp.to_models.first
      end
    end
  end
end
