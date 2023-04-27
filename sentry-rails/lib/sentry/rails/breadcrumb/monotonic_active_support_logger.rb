require 'sentry/rails/instrument_payload_cleanup_helper'

module Sentry
  module Rails
    module Breadcrumb
      module MonotonicActiveSupportLogger
        class << self
          include InstrumentPayloadCleanupHelper

          def add(name, started, _finished, _unique_id, data)
            # skip Rails' internal events
            return if name.start_with?('!')

            if data.is_a?(Hash)
              # we should only mutate the copy of the data
              data = data.dup
              cleanup_data(data)
            end

            crumb = Sentry::Breadcrumb.new(
              data: data,
              category: name,
              timestamp: started.to_i
            )
            Sentry.add_breadcrumb(crumb)
          end

          def inject
            @subscriber = ::ActiveSupport::Notifications.monotonic_subscribe(/.*/) do |name, started, finished, unique_id, data|
              # we only record events that has a float as started timestamp
              add(name, started, finished, unique_id, data) if started.is_a?(Float)
            end
          end

          def detach
            ::ActiveSupport::Notifications.unsubscribe(@subscriber)
          end
        end
      end
    end
  end
end
