# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bundle_daemon/version'

Gem::Specification.new do |spec|
  spec.name          = 'bundle_daemon'
  spec.version       = BundleDaemon::VERSION
  spec.authors       = ['Donavan Stanley']
  spec.email         = ['stanleyd@grangeinsurance.com']
  spec.summary       = %q{A daemon to run bundle installs.}
  spec.description   = %q{See summary.}
  spec.homepage      = 'https://github.com/orgs/grange-insurance'
  spec.license       = 'MIT'
  
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 2.14'
  spec.add_development_dependency 'simplecov', '~> 0.9'

  #spec.add_dependency 'sneakers'
end
