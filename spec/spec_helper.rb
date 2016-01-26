require 'rubygems'
require 'bundler'
require 'rspec'
require 'pry'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

RSpec.configure do |c|
  c.color = true

  c.before(:all) do
    @redis = Redis.new(db: 5)
  end

  c.before(:each) do
    @redis.flushdb
  end
end

require 'redis_mq'
