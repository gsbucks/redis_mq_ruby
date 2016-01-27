module RedisMQ
  class Client
    def initialize(queue:, redis: Redis.new, timeout: 0)
      @redis = redis
      @queue = queue
      @timeout = timeout
    end

    def rpc(method, params)
      id, package = RPC.package_request(method, params)
      broadcast(package)
      from_queue, result = redis.blpop("#{queue}-result-#{id}", @timeout)
      RPC.unpackage_result(result)
    end

    def broadcast(object)
      redis.lpush(queue, object)
    end

    private

    attr_accessor :queue, :redis
  end
end
