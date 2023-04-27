# frozen_string_literal: true

module Sentry
  module Puma
    module Server
      def lowlevel_error(e, env, status = 500)
        result = super

        begin
          Sentry.capture_exception(e) do |scope|
            scope.set_rack_env(env)
          end
        rescue StandardError
          # if anything happens, we don't want to break the app
        end

        result
      end
    end
  end
end

Sentry.register_patch(Sentry::Puma::Server, Puma::Server) if defined?(Puma::Server)
