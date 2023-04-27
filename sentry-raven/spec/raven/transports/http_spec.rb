require 'spec_helper'

RSpec.describe Raven::Transports::HTTP do
  let(:config) { Raven::Configuration.new.tap { |c| c.dsn = 'http://12345@sentry.localdomain/sentry/42' } }
  let(:client) { Raven::Client.new(config) }

  it 'should set a custom User-Agent' do
    expect(client.send(:transport).conn.headers[:user_agent]).to eq("sentry-ruby/#{Raven::VERSION}")
  end

  context 'when event is not allowed (by sampling)' do
    let(:event) do
      JSON.generate(Raven.capture_message('test').to_hash)
    end

    before do
      config.sample_rate = 0.5
      allow(Random::DEFAULT).to receive(:rand).and_return(0.6)
    end

    it 'logs correct message' do
      expect(config.logger).to receive(:debug).with('Raven HTTP Transport connecting to http://sentry.localdomain/sentry')
      expect(config.logger).to receive(:debug).with('Event not sent: Excluded by random sample')
      client.transport.send_event('test_auth', event)
    end
  end

  it 'should raise an error on 4xx responses' do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('sentry/api/42/store/') { [404, {}, 'not found'] }
    end
    client.configuration.http_adapter = [:test, stubs]

    event = JSON.generate(Raven.capture_message('test').to_hash)
    expect do
      client.send(:transport).send_event('test',
                                         event)
    end.to raise_error(Raven::Error, /the server responded with status 404/)

    stubs.verify_stubbed_calls
  end

  it 'should raise an error on 5xx responses' do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('sentry/api/42/store/') { [500, {}, 'error'] }
    end
    client.configuration.http_adapter = [:test, stubs]

    event = JSON.generate(Raven.capture_message('test').to_hash)
    expect do
      client.send(:transport).send_event('test',
                                         event)
    end.to raise_error(Raven::Error, /the server responded with status 500/)

    stubs.verify_stubbed_calls
  end

  it 'should add header info message to the error' do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post('sentry/api/42/store/') { [400, { 'x-sentry-error' => 'error_in_header' }, 'error'] }
    end
    client.configuration.http_adapter = [:test, stubs]

    event = JSON.generate(Raven.capture_message('test').to_hash)
    expect { client.send(:transport).send_event('test', event) }.to raise_error(Raven::Error, /error_in_header/)

    stubs.verify_stubbed_calls
  end

  it 'allows to customise faraday' do
    builder = spy('faraday_builder')
    expect(Faraday).to receive(:new).and_yield(builder)

    client.configuration.faraday_builder = proc { |b| b.request :instrumentation }

    client.send(:transport)

    expect(builder).to have_received(:request).with(:instrumentation)
  end
end
