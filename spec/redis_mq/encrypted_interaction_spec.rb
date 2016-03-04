require 'spec_helper'

module RedisMQ
  describe 'encrypted server/client interaction' do
    let(:cipher)      { OpenSSL::Cipher::AES.new(128, :CBC).tap{|c| c.encrypt } }
    let(:iv)          { cipher.random_iv }
    let(:key)         { cipher.random_key }
    let(:queue)       { 'Anything' }
    let(:encryptor)   { Encryptor.new(key, iv) }
    let(:client)      { Client.new(queue: queue, encryptor: encryptor, redis: @redis) }
    let(:server)      { Server.new(queue: queue, encryptor: encryptor, redis: @redis) }
    let(:transit_msg) { @redis.lrange(queue,0,0)[0] }
    let(:message)     { 'chicken' }

    it 'encypts messages in transit but can decrypt' do
      client.broadcast(message)
      expect(transit_msg).not_to be_empty
      expect(transit_msg).not_to include(message)

      server.process_one{|result| expect(result).to eq(message) }
    end
  end
end
