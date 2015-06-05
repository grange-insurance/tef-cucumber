# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tef/queuebert/version'

Gem::Specification.new do |spec|
  spec.name          = 'tef-queuebert'
  spec.version       = TEF::Queuebert::VERSION
  spec.authors       = ['Donavan Stanley', 'Eric Kessler']
  spec.email         = ['donavan.stanley@gmail.com', 'morrow748@gmail.com']
  spec.summary       = %q{The queueing portion of the TEF}
  spec.description   = %q{It makes queueing Cucumber tasks easy.}
  spec.homepage      = 'https://github.com/orgs/grange-insurance'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'cucumber', '~> 2.0'
  spec.add_development_dependency 'bundler'    , '~> 1.6'
  spec.add_development_dependency 'rake'       , '~> 10.3'
  spec.add_development_dependency 'rspec'      , '~> 3.0'
  spec.add_development_dependency 'rspec-wait' , '= 0.0.2'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  spec.add_dependency 'tef-core', '~> 0'
  spec.add_dependency 'cuke_slicer', '~>1.0'
  spec.add_dependency 'bunny', '~> 1.4'
end
