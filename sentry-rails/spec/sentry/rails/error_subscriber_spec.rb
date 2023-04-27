require 'spec_helper'
require 'sentry/rails/error_subscriber'

RSpec.describe Sentry::Rails::ErrorSubscriber,
               skip: Rails.version.to_f < 7.0 ? 'ActiveSupport::ErrorReporter not available until Rails 7' : false do
  describe '#report' do
    it 'does not mutate context' do
      context = { tags: { foo: 'bar' } }
      expect do
        described_class.new.report(StandardError.new, handled: true, severity: :error, context: context)
      end.not_to change {
                   context
                 }
    end

    it 'sets handled tag' do
      expect(Sentry::Rails).to receive(:capture_exception) do |_, tags:, **_|
        expect(tags[:handled]).to eq(true)
      end
      event = described_class.new.report(StandardError.new, handled: true, severity: :error, context: {})
    end

    context 'when source is not nil' do
      it 'does not send event when source is skipped' do
        expect(Sentry::Rails).not_to receive(:capture_exception)
        described_class.new.report(StandardError.new, handled: true, severity: :error, context: {},
                                                      source: 'foo_cache_store.active_support')
      end

      it 'sends event when source is not skipped' do
        expect(Sentry::Rails).to receive(:capture_exception)
        described_class.new.report(StandardError.new, handled: true, severity: :error, context: {}, source: 'foo')
      end

      it 'sets the source as a tag' do
        expect(Sentry::Rails).to receive(:capture_exception) do |_, tags:, **_|
          expect(tags[:source]).to eq('foo')
        end
        described_class.new.report(StandardError.new, handled: true, severity: :error, context: {}, source: 'foo')
      end
    end

    context 'when passed a context with tags key' do
      context 'when tags is a Hash' do
        it 'merges the tags into the event' do
          expect(Sentry::Rails).to receive(:capture_exception) do |_, tags:, **_|
            expect(tags[:foo]).to eq('bar')
          end
          described_class.new.report(StandardError.new, handled: true, severity: :error,
                                                        context: { tags: { foo: 'bar' } })
        end

        it 'does not pass the tags to the context' do
          expect(Sentry::Rails).to receive(:capture_exception) do |_, contexts:, **_|
            expect(contexts['rails.error']).not_to have_key(:tags)
          end
          described_class.new.report(StandardError.new, handled: true, severity: :error,
                                                        context: { tags: { foo: 'bar' } })
        end
      end

      context 'when tags is not a Hash' do
        it 'does not merge the tags into the event' do
          expect(Sentry::Rails).to receive(:capture_exception) do |_, tags:, **_|
            expect(tags).not_to have_key(:foo)
          end
          described_class.new.report(StandardError.new, handled: true, severity: :error, context: { tags: 'foo' })
        end

        it 'passes the tags to the context' do
          expect(Sentry::Rails).to receive(:capture_exception) do |_, contexts:, **_|
            expect(contexts['rails.error'][:tags]).to eq('foo')
          end
          described_class.new.report(StandardError.new, handled: true, severity: :error, context: { tags: 'foo' })
        end
      end
    end
  end
end
