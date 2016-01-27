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
    rescue Exception => e
      respond(rpc_request.id, RPC.package_error(rpc_request.id, e))
    else
      respond(rpc_request.id, RPC.package_result(rpc_request.id, result))
    end

    def respond(id, rpc_object)
      result_list = "#{server.queue}-result-#{id}"
      server.redis.multi do |trans|
        trans.lpush(result_list, rpc_object)
        trans.expire(result_list, @result_expiry)
      end
      true
    end

    attr_accessor :server, :dispatcher
  end
end
