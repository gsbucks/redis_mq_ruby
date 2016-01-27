require 'json'

module RedisMQ
  class InvalidResponseException < Exception; end

  class RPC
    RPC_VERSION = '2.0'

    def self.package(method, params)
      id = SecureRandom.hex
      [
        id,
        {
          jsonrpc: '2.0',
          method: method,
          params: params,
          id: SecureRandom.hex
        }.to_json
      ]
    end

    def self.unpackage(response)
      rpc = JSON.parse(response)
      raise InvalidResponseException, response if rpc['jsonrpc'] != RPC_VERSION
      raise InvalidResponseException, response if rpc['id'].nil? || rpc['id'].empty?
      rpc.has_key?('result') ? rpc['result'] : rpc['error']
    end
  end
end
