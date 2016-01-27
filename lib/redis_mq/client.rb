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
      RPC.unpackage_result(redis.blpop("#{queue}-result-#{id}", @timeout))
    end

    def broadcast(object)
      redis.lpush(queue, object)
    end

    private

    attr_accessor :queue, :redis
  end
end
