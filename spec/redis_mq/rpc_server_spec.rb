require 'spec_helper'

describe RedisMQ::RPCServer do
  let(:queue)       { 'whatever' }
  let(:client)      { described_class.new(dispatcher, queue: queue, redis: @redis) }
  let(:dispatcher)  { double('Dispatcher') }
  let(:rpc_package) {{
    jsonrpc: '2.0',
    id: '123',
    method: 'translate',
    params: 'gibberish'
  }}

  describe '#non_blocking_process_one' do
    subject { client.non_blocking_process_one }

    context 'list doesnt exist' do
      it { is_expected.to be_nil }
    end

    context 'something in list' do
      before { @redis.lpush(queue, rpc_package.to_json) }

      it 'calls method on dispatcher' do
        expect(dispatcher).to receive(rpc_package[:method]).with(rpc_package[:params])
        subject
      end
    end
  end

  describe '#commit' do
    let(:object) { '1' }

    before { @redis.lpush(client.retry_queue, object) }
    subject { client.commit(object) }

    it 'removes the object from the retry queue' do
      subject
      expect(@redis.lpop(client.retry_queue)).to be_nil
    end
  end

  describe '#process_one' do
    context 'element in the queue' do
      before { @redis.lpush(queue, rpc_package.to_json) }

      it 'calls out to dispatcher' do
        expect(dispatcher).to receive(rpc_package[:method]).with(rpc_package[:params])
        client.process_one
      end
    end
  end

  describe '#process' do
    let(:object) { '1' }

    context 'empty queue' do
      it 'blocks until it can process' do
        expect{ 
          Timeout.timeout(0.3) do
            client.process
            fail 'Process method should be blocking'
          end
        }.to raise_error Timeout::Error
      end
    end

    context 'given quantity of iterations' do
      let(:rpc_package_2) {{
        jsonrpc: '2.0',
        id: '124',
        method: 'cook',
        params: 'eggs'
      }}
      let(:packages) { [rpc_package, rpc_package_2] }

      before { packages.each{|rpc| @redis.lpush(queue, rpc.to_json) } }
      subject { client.process(packages.length) }

      it 'stops after iteration total, false dispatch left on retry queue' do
        expect(dispatcher).to(
          receive(rpc_package[:method]).once.with(rpc_package[:params]).and_return(true)
        )
        expect(dispatcher).to(
          receive(rpc_package_2[:method]).once.with(rpc_package_2[:params]).and_return(false)
        )
        subject
        expect(@redis.llen(client.queue)).to eq(0)
        expect(@redis.llen(client.retry_queue)).to eq(1)
        expect(@redis.lpop(client.retry_queue)).to eq(rpc_package_2.to_json)
      end
    end
  end

end
