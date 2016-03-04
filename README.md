RedisMQ
=============
Based on reliable queue pattern: http://redis.io/commands/rpoplpush
A good post about how this can be used: http://blog.carbonfive.com/2014/04/28/micromessaging-connecting-heroku-microservices-wredis-and-rabbitmq/

Defines RedisMQ::Server/Client to send arbitrary or JSON-RPC based messages through redis. Supports encrypting transferred packets if you're just using redis for inter-service communication and don't want to set up a tunnel.

Eventually I'd like it to include an executable that can easily be called on a background heroku dyno to serve these requests


Installation
----------------
    $ not yet

Usage
----------------
```ruby

### Client ###
client = RedisMQ::Client.new(queue: 'QueueName', redis: $redis)

# Send request through JSON-RPC and wait for result
result = client.rpc('kick', ['Ball', 'Can'])

# Send a message and don't expect a response. No marshalling done to object, so if your
# server expects JSON, you should give this JSON
client.broadcast( { bro: 'hope you can handle this' }.to_json )

### Server ###
server = RedisMQ::Server.new(queue: 'QueueName', redis: $redis)

# Blocking, will monitor queue until killed
# process(3) to limit the quantity of messages to be processed before returning
server.process do |message|
  # whatever you want to do with the messages
  # returning a truthy value will automatically remove it from the retry-queue
end

# same as server.process(1), but may exclude block. Message is returned in that case
server.process_one
server.non_blocking_process_one # same as above, but will just return if queue is empty


### RPC Server ###
# Define a dispatcher to handle the RPC requests
class RequestHandler
  def print(input)
    puts input
  end
end

dispatcher = RequestHandler.new
server = RedisMQ::Server.new(queue: 'QueueName', redis: $redis)
rpc_server = RedisMQ::RPCServer.new(dispatcher, server)

# Same methods as RedisMQ::Server, but instead of giving a block, the requests are sent to dispatcher
# For example...
client = RedisMQ::Client.new(queue: 'QueueName')
client.rpc('print', 'stuff')

rpc_server.process_one
# Results in 'stuff' being printed by RequestHandler


### Encryption ###
# Automatically encrypts if a RedisMQ::Encryptor is given to client/server.

cipher = OpenSSL::Cipher::AES.new(128, :CBC)
cipher.encrypt
key = cipher.random_key
iv = cipher.random_iv

encryptor = RedisMQ::Encryptor.new(key, iv, 256) #(128 default)
server = RedisMQ::Server.new(queue: 'QueueName', redis: $redis, encryptor: encryptor)
client = RedisMQ::Client.new(queue: 'QueueName', redis: $redis, encryptor: encryptor)
client.broadcast('stuff')
# 'stuff' gets encrypted before pushing to redis
server.process { |decrypted_message| #'stuff' }

# All server processing calls not taking a block return the encrypted result
# because otherwise calling commit would fail. They must be manually decrypted.
encrypted_still = server.process
decrypted_message = encryptor.decrypt(encrypted_still)
server.commit(encrypted_still)


```

Testing
----------------
    $ bundle install
    $ rspec


Copyright
----------------

Copyright (c) 2016 Alta Motors. See LICENSE.txt for further details.
