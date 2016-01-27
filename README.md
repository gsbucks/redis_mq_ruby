RedisMQ
=============
Based on reliable queue pattern: http://redis.io/commands/rpoplpush

Adds RedisMQ::Server/Client to send arbitrary or JSON-RPC based messages through redis. Supports encrypting transferred packets if you're just using redis for inter-service communication and don't want to set up a tunnel.

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

```

Testing
----------------
    $ bundle install
    $ rspec


Copyright
----------------

Copyright (c) 2016 Alta Motors. See LICENSE.txt for further details.
