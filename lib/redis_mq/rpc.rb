require 'json'

module RedisMQ
  class InvalidRPCException < Exception; end
  class InvalidRequestException < Exception; end

  class RPCRequest < Struct.new(:id, :method, :params)
  end

  class RPC
    RPC_VERSION = '2.0'

    class << self
      def package_request(method, params)
        id = SecureRandom.hex
        [
          id,
          {
            jsonrpc: '2.0',
            method: method,
            params: params,
            id: id
          }.to_json
        ]
      end

      def unpackage_request(response)
        rpc = parse_and_validate(response)
        if rpc['method'].nil? || rpc['method'].empty?
          raise InvalidRequestException, "#{response} lacks method"
        end
        RPCRequest.new(rpc['id'], rpc['method'], rpc['params'])
      end

      def package_result(id, result)
        raise ArgumentError, 'id is required' if id.nil? || id.empty?
        {
          jsonrpc: '2.0',
          result: result,
          id: id
        }.to_json
      end

      def package_error(id, error_message)
        raise 'not implemented'
      end

      def unpackage_result(response)
        rpc = parse_and_validate(response)
        rpc.has_key?('result') ? rpc['result'] : rpc['error']
      end

      private

      def parse_and_validate(response)
        rpc = JSON.parse(response)
        raise InvalidRPCException, "#{response} incorrect version" if rpc['jsonrpc'] != RPC_VERSION
        raise InvalidRPCException, "#{response} lacks ID" if rpc['id'].nil? || rpc['id'].empty?
        rpc
      end
    end
  end
end
