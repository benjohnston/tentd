require 'hashie'

module TentD
  class API
    class Middleware
      include Authorizable

      def initialize(app)
        @app = app
      end

      def call(env)
        env = Hashie::Mash.new(env) unless env.kind_of?(Hashie::Mash)
        response = action(env)
        response.kind_of?(Hash) ? @app.call(response) : response
      rescue Unauthorized
        [403, {}, ['Unauthorized']]
      rescue Sequel::ValidationFailed, Sequel::DatabaseError
        [422, {}, ['Invalid Attributes']]
      rescue Exception => e
        if ENV['RACK_ENV'] == 'test'
          raise
        elsif defined?(Airbrake)
          Airbrake.notify_or_ignore(e, :rack_env => env)
        else
          puts $!.inspect, $@
        end
        [500, {}, ['Internal Server Error']]
      end

      private

      def self_uri(env)
        uri = URI('')
        uri.host = env.HTTP_HOST
        uri.scheme = env['rack.url_scheme']

        port = (env.HTTP_X_FORWARDED_PORT || env.SERVER_PORT).to_i
        uri.port = port unless [80, 443].include?(port)

        uri
      end
    end
  end
end
