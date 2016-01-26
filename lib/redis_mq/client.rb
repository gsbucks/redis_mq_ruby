module RedisMQ
  class Client
    def initialize(queue_name: 'random', redis: Redis.new, timeout: 0)
    end
  end
end
