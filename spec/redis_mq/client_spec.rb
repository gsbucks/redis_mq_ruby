require 'spec_helper'

describe RedisMQ::Client do
  let(:client) { described_class.new(redis: @redis) }

  it 'starting' do
    p client.class
  end
end
