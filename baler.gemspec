lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baler/version'

Gem::Specification.new do |spec|
  spec.name        = "baler"
  spec.version     = Baler::VERSION
  spec.summary     = "The glue between hopper and hay."
  spec.description = "Glues hopper and hay -- an abstraction layer on RabbitMQ, and a generic dependency-based task management system, respectively -- together, using a configuration-based approach."
  spec.platform    = "ruby"

  spec.homepage    = "https://github.com/azanar/baler"
  spec.license     = "MIT"

  spec.authors     = ["Ed Carrel"]
  spec.email       = ["edward@carrel.org"]

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_runtime_dependency 'hay'
  spec.add_runtime_dependency 'hopper'

  spec.add_development_dependency 'edger' 
  spec.add_development_dependency 'test-unit' 
  spec.add_development_dependency 'mocha' 
  spec.add_development_dependency 'simplecov'
end
