module RedisMQ
  class Server
    attr_accessor :queue, :redis

    def initialize(queue:, redis: Redis.new, timeout: 0, encryptor: MockEncryptor.new)
      @redis = redis
      @queue = queue
      @timeout = timeout
      @encryptor = encryptor
    end

    def process(count = 0, &block)
      decrement_count = count.to_i > 0
      count -= 1 if count > 0

      while count >= 0
        process_one(&block)
        count -= 1 if decrement_count
      end
    end

    def process_one(&block)
      result = redis.brpoplpush(queue, retry_queue, @timeout)
      if block_given?
        commit(result) if yield(@encryptor.decrypt(result))
      else
        result
      end
    end

    def non_blocking_process_one
      redis.rpoplpush(queue, retry_queue)
    end

    def commit(message)
      redis.lrem(retry_queue, 0, message)
    end

    def retry_queue
      @rq ||= "#{@queue}_retry"
    end

  end
end
