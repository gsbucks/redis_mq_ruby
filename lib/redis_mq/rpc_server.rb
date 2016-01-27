module RedisMQ
  class RPCServer
    def initialize(dispatcher, server)
      @server = server
      @dispatcher = dispatcher
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
      @server.redis.lpush(
        "#{@server.queue}-result-#{rpc_request.id}",
        RPC.package_result(rpc_request.id, result)
      )
      true
    end

    attr_accessor :server, :dispatcher
  end
end
