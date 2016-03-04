module RedisMQ
  class RPCResponseTimeout < Exception; end

  class Client
    def initialize(queue:, redis: Redis.new, encryptor: MockEncryptor.new, timeout: 0)
      @redis = redis
      @queue = queue
      @timeout = timeout
      @encryptor = encryptor
    end

    def rpc(method, params)
      id, package = RPC.package_request(method, params)
      broadcast(package)
      from_queue, result = redis.blpop("#{queue}-result-#{id}", @timeout)
      raise RPCResponseTimeout if from_queue.nil?
      RPC.unpackage_result(result)
    end

    def broadcast(object)
      redis.lpush(queue, @encryptor.encrypt(object))
    end

    private

    attr_accessor :queue, :redis
  end
end
