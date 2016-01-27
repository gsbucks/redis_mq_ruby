require 'spec_helper'

describe RedisMQ::Server do
  let(:queue)  { 'whatever' }
  let(:client) { described_class.new(queue: queue, redis: @redis) }

  describe '#non_blocking_process_one' do
    subject { client.non_blocking_process_one }

    context 'nothing in list' do
      before { @redis.lpush(queue, '1'); @redis.lpop(queue) }
      it { is_expected.to be_nil }
    end

    context 'list doesnt exist' do
      it { is_expected.to be_nil }
    end

    context 'something in list' do
      let(:object) { '1' }
      before { @redis.lpush(queue, object) }

      it { is_expected.to eq(object) }

      it 'pushes to retry queue until committed' do
        subject
        expect(@redis.lpop(client.retry_queue)).to eq(object)
      end
    end
  end

  describe '#commit' do
    subject { client.commit(object) }

    context 'something in rety queue' do
      let(:object) { '1' }
      before { @redis.lpush(client.retry_queue, object) }

      it 'removes the object from the retry queue' do
        subject
        expect(@redis.lpop(client.retry_queue)).to be_nil
      end
    end
  end

  describe '#process_one' do
    context 'element in the queue' do
      let(:object) { '1' }
      before { @redis.lpush(queue, object) }

      context 'no block given' do
        it 'doesnt remove the object from the retry queue' do
          expect(client.process_one).to eq(object)
        end
      end

      context 'block returns falsey' do
        it 'doesnt remove the object from the retry queue' do
          client.process_one do |result|
            expect(result).to eq(object)
            false
          end
          expect(@redis.lpop(client.retry_queue)).to eq(object)
        end
      end

      context 'block returns truthiness' do
        it 'removes the object from the retry queue' do
          client.process_one { |result| expect(result).to eq(object) }
          expect(@redis.lpop(client.retry_queue)).to be_nil
        end
      end
    end
  end

  describe '#process' do
    let(:object) { '1' }

    context 'without iterations' do
      before { @redis.lpush(queue, object) }

      it 'blocks after queue is empty' do
        expect{ 
          Timeout.timeout(0.3) do
            client.process do |result|
              expect(result).to eq(object)
              true
            end
            fail 'Process method should be blocking'
          end
        }.to raise_error Timeout::Error
      end
    end

    context 'given quantity of iterations' do
      let(:iterations) { 3 }
      before { (iterations + 1).times{ @redis.lpush(queue, object) } }

      it 'stops after appropriate quantity of iterations' do
        client.process(iterations) do |result|
          expect(result).to eq(object)
          true
        end
        expect(@redis.lpop(client.queue)).to eq(object)
        expect(@redis.lpop(client.queue)).to be_nil
      end
    end
  end

end
