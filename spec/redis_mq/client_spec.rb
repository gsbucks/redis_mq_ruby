require 'spec_helper'

describe RedisMQ::Client do
  let(:queue)  { 'whatever' }
  let(:client) { described_class.new(queue: queue, redis: @redis) }

  describe '#broadcast' do
    subject { client.broadcast(object) }
    let(:object) { 'Butter' }

    it 'pushes whatever is given to it to the queue' do
      subject
      expect(@redis.lpop(queue)).to eq(object)
    end
  end

  describe '#rpc' do
    subject { client.rpc(method, params) }
    let(:method) { 'spread' }
    let(:params) { 'Butter' }
    let(:expected_result) { 'Savory' }

    it 'pushes to queue and blocks for the result' do
      expect(@redis).to receive(:blpop) { |*args|
        expect(args[0]).to match(/#{queue}-result-[[:alnum:]]{32}/)
        expect(args[1]).to eq(0)
      }.and_return([
        queue,
        {
          jsonrpc: '2.0',
          id: '123',
          result: expected_result
        }.to_json
      ])
      expect(subject).to eq(expected_result)
    end
  end
end
