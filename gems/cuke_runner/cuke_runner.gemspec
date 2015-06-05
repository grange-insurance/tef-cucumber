# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cuke_runner/version'

Gem::Specification.new do |spec|
  spec.name          = 'cuke_runner'
  spec.version       = CukeRunner::VERSION
  spec.authors       = ['Donavan Stanley', 'Eric Kessler']
  spec.email         = ['donavan.stanley@gmail.com', 'morrow748@gmail.com']
  spec.summary       = %q{Run cucumber based off of JSON data}
  spec.description   = %q{Run cucumber based off of JSON data. Part of the TEF project}
  spec.homepage      = 'https://github.com/orgs/grange-insurance'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'cucumber', '~> 2.0'
  spec.add_development_dependency 'bundler' , '~> 1.6'
  spec.add_development_dependency 'rake'    , '~> 10.3'
  spec.add_development_dependency 'rspec'   , '~> 2.14'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  spec.add_dependency 'task_runner', '~> 0.0'
  spec.add_dependency 'cuke_commander', '~> 1.0'
end
