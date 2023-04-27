module Raven
  module Utils
    module ExceptionCauseChain
      def self.exception_to_array(exception)
        if exception.respond_to?(:cause) && exception.cause
          exceptions = [exception]
          while exception.cause
            exception = exception.cause
            break if exceptions.any? { |e| e.equal?(exception) }

            exceptions << exception
          end
          exceptions
        else
          [exception]
        end
      end
    end
  end
end
