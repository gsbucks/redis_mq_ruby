module RedisMQ
  class RPCServer
    def initialize(dispatcher, *args)
      @server = Server.new(*args)
      @dispatcher = dispatcher
    end

    def process(*args)
      @server.process(*args) do |request|
        request.nil? || dispatcher.send(*RPC.unpackage_request(request))
      end
    end

    def process_one
      @server.process_one do |request|
        request.nil? || dispatcher.send(*RPC.unpackage_request(request))
      end
    end

    def non_blocking_process_one
      request = @server.non_blocking_process_one
      return if request.nil?
      dispatcher.send(*RPC.unpackage_request(request))
    end

    # Miss ActiveSupport's delegate module
    [:commit, :retry_queue, :queue].each do |method|
      define_method method do |*args, &block|
        @server.send(method, *args, &block)
      end
    end

    private

    attr_accessor :server, :dispatcher
  end
end
