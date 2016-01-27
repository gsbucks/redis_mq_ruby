require 'spec_helper'

module RedisMQ
  describe RPCServer do
    let(:queue)       { 'whatever' }
    let(:server)      { Server.new(queue: queue, redis: @redis) }
    let(:rpc_server)  { described_class.new(dispatcher, server) }
    let(:dispatcher)  { double('Dispatcher') }
    let(:rpc_package) {{
      jsonrpc: '2.0',
      id: '123',
      method: 'translate',
      params: 'gibberish'
    }}

    describe '#non_blocking_process_one' do
      subject { rpc_server.non_blocking_process_one }

      context 'list doesnt exist' do
        it { is_expected.to be true }
      end

      context 'something in list' do
        before { @redis.lpush(queue, rpc_package.to_json) }

        it 'calls method on dispatcher' do
          expect(dispatcher).to receive(rpc_package[:method]).with(rpc_package[:params])
          subject
        end
      end
    end

    describe '#process_one' do
      let(:dispatch_result) { 'Anything' }

      context 'element in the queue' do
        before { @redis.lpush(queue, rpc_package.to_json) }

        it 'calls out to dispatcher, placing result on return queue' do
          expect(dispatcher).to(
            receive(rpc_package[:method]).with(rpc_package[:params]).and_return(dispatch_result)
          )
          rpc_server.process_one
          expect(@redis.lpop("#{queue}-result-#{rpc_package[:id]}")).to(
            match(/"result":"#{dispatch_result}"/)
          )
        end
      end

      context 'an error occurs during dispatch' do
        before { @redis.lpush(queue, rpc_package.to_json) }

        it 'pushes a JSON-RPC error object onto the response list' do
          expect(dispatcher).to(
            receive(rpc_package[:method]).with(rpc_package[:params]).and_raise(ArgumentError)
          )
          rpc_server.process_one
          expect(@redis.lpop("#{queue}-result-#{rpc_package[:id]}")).to(
            match(/"error"/)
          )
        end
      end
    end

    describe '#process' do
      let(:object) { '1' }

      context 'empty queue' do
        it 'blocks until it can process' do
          expect{ 
            Timeout.timeout(0.3) do
              rpc_server.process
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
        subject { rpc_server.process(packages.length) }

        it 'stops after iteration total' do
          expect(dispatcher).to(
            receive(rpc_package[:method]).once.with(rpc_package[:params]).and_return(true)
          )
          expect(dispatcher).to(
            receive(rpc_package_2[:method]).once.with(rpc_package_2[:params]).and_return(false)
          )
          subject
          expect(@redis.llen(server.queue)).to eq(0)
          expect(@redis.llen(server.retry_queue)).to eq(0)
          expect(@redis.llen("#{queue}-result-#{rpc_package[:id]}")).to eq(1)
          expect(@redis.llen("#{queue}-result-#{rpc_package_2[:id]}")).to eq(1)
        end
      end
    end
  end
end
