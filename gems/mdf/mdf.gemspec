# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mdf/version'

Gem::Specification.new do |spec|
  spec.name          = 'mdf'
  spec.version       = MDF::VERSION
  spec.authors       = ["Donavan"]
  spec.email         = ["jdonavan@jdonavan.com"]
  spec.summary       = %q{JSON formatter for cucumber, which includes metadata.}
  spec.description   = %q{JSON formatter for cucumber, which includes metadata.  Part of the TEF project.}
  spec.homepage      = "https://github.com/orgs/grange-insurance"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency 'rspec'   , '~> 3.0'

  spec.add_dependency 'cucumber', '~> 2.0'
end
