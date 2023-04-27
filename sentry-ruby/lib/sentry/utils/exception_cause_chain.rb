# frozen_string_literal: true

module Sentry
  module Utils
    module ExceptionCauseChain
      def self.exception_to_array(exception)
        exceptions = [exception]

        while exception.cause
          exception = exception.cause
          break if exceptions.any? { |e| e.equal?(exception) }

          exceptions << exception
        end

        exceptions
      end
    end
  end
end
