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
In progress
```

Testing
----------------
    $ bundle install
    $ rake


Copyright
----------------

Copyright (c) 2016 Alta Motors. See LICENSE.txt for further details.
