# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_mq/version'

Gem::Specification.new do |s|
  s.name        = 'redis_mq'
  s.version     = RedisMQ::VERSION
  s.authors     = ['Alta Motors']
  s.email       = ['web@altamotors.co']
  s.homepage    = "https://github.com/gsbucks/redis_mq"
  s.summary     = %q{A client/server for Redis backed messaging supporting JSON-RPC 2.0}
  s.description = %q{
    Based on reliable queue pattern: http://redis.io/commands/rpoplpush
  }

  s.licenses    = ['MIT']

  s.rubyforge_project = "redis_mq"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,features}/*`.split('\n')
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'redis', '~> 3.2'

  s.add_development_dependency 'rspec', '~> 3.3', '>= 3.3.0'
  s.add_development_dependency 'pry-doc'
end
