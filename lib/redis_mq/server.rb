module RedisMQ
  class Server
    def initialize(queue:, redis: Redis.new, timeout: 0)
    end

    def process(&block)
    end

    def process_one(&block)
    end
  end
end
