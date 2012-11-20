require 'securerandom'
require 'tentd/core_ext/hash/slice'

module TentD
  module Model
    class App < Sequel::Model(:apps)
      include RandomPublicId
      include Serializable

      plugin :serialization
      serialize_attributes :pg_array, :redirect_uris
      serialize_attributes :json, :scopes

      one_to_many :authorizations, :class => AppAuthorization
      one_to_many :posts
      one_to_many :post_versions

      def before_create
        self.public_id ||= random_id
        self.mac_key_id ||= 'a:' + SecureRandom.hex(4)
        self.mac_key ||= SecureRandom.hex(16)
        self.mac_algorithm ||= 'hmac-sha-256'
        self.user_id ||= User.current.id
        self.created_at = Time.now
        super
      end

      def before_save
        self.updated_at = Time.now
        super
      end

      def self.create_from_params(params={})
        create(params.slice(*public_attributes))
      end

      def self.update_from_params(id, params)
        app = first(:id => id)
        return unless app
        app.update(params.slice(*public_attributes))
        app
      end

      def self.public_attributes
        [:name, :description, :url, :icon, :scopes, :redirect_uris]
      end

      def auth_details
        attributes.slice(:mac_key_id, :mac_key, :mac_algorithm)
      end

      def as_json(options = {})
        attributes = super

        if options[:mac]
          [:mac_key, :mac_key_id, :mac_algorithm].each { |key|
            attributes[key] = send(key)
          }
        end

        attributes[:authorizations] = authorizations.map { |a| a.as_json(options.merge(:self => nil)) }

        Array(options[:exclude]).each { |k| attributes.delete(k) if k }
        attributes
      end
    end
  end
end

# module TentD
#   module Model
#     class XApp
#       include DataMapper::Resource
#       include RandomPublicId
#       include Serializable
#       include UserScoped
#
#       storage_names[:default] = 'apps'
#
#       property :id, Serial
#       property :name, Text, :required => true, :lazy => false
#       property :description, Text, :lazy => false
#       property :url, Text, :required => true, :lazy => false
#       property :icon, Text, :lazy => false
#       property :redirect_uris, Array, :lazy => false, :default => []
#       property :scopes, Json, :default => {}, :lazy => false
#       property :mac_key_id, String, :default => lambda { |*args| 'a:' + SecureRandom.hex(4) }, :unique => true
#       property :mac_key, String, :default => lambda { |*args| SecureRandom.hex(16) }
#       property :mac_algorithm, String, :default => 'hmac-sha-256'
#       property :mac_timestamp_delta, Integer
#       property :created_at, DateTime
#       property :updated_at, DateTime
#       property :deleted_at, ParanoidDateTime
#
#       has n, :authorizations, 'TentD::Model::AppAuthorization', :constraint => :destroy
#       has n, :posts, 'TentD::Model::Post', :constraint => :set_nil
#       has n, :post_versions, 'TentD::Model::PostVersion', :constraint => :set_nil
#     end
#   end
# end
