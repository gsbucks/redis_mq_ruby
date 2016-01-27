module RedisMQ
  class RPCServer
    def initialize(dispatcher, server, result_expiry: 5)
      @server = server
      @dispatcher = dispatcher
      @result_expiry = result_expiry
    end

    def process(*args)
      @server.process(*args){ |request| request.nil? || handle_rpc_request(request) }
    end

    def process_one
      @server.process_one { |request| request.nil? || handle_rpc_request(request) }
    end

    def non_blocking_process_one
      request = @server.non_blocking_process_one
      request.nil? || handle_rpc_request(request)
    end

    private

    def handle_rpc_request(request)
      rpc_request = RPC.unpackage_request(request)
      result = dispatcher.send(*[rpc_request.method, rpc_request.params].compact)
      server.redis.multi do |trans|
        result_list = "#{@server.queue}-result-#{rpc_request.id}"
        trans.lpush(result_list, RPC.package_result(rpc_request.id, result))
        trans.expire(result_list, @result_expiry)
      end
      true
    end

    attr_accessor :server, :dispatcher
  end
end
