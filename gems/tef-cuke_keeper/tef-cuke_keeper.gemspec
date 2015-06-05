# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tef/cuke_keeper/version'

Gem::Specification.new do |spec|
  spec.name          = 'tef-cuke_keeper'
  spec.version       = TEF::CukeKeeper::VERSION
  spec.authors       = ['Donavan Stanley', 'Eric Kessler']
  spec.email         = ['donavan.stanley@gmail.com', 'morrow748@gmail.com']
  spec.summary       = %q{A TEF keeper that specializes in cucumber task results.}
  spec.description   = %q{Part of the TEF project}
  spec.homepage      = 'https://github.com/orgs/grange-insurance'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'cucumber'  , '~> 2.0'
  spec.add_development_dependency 'bundler'    , '~> 1.6'
  spec.add_development_dependency 'rake'       , '~> 10.3'
  spec.add_development_dependency 'rspec'      , '~> 3.0'
  spec.add_development_dependency 'rspec-wait' , '= 0.0.2'
  spec.add_development_dependency 'simplecov', '~> 0.9'
  spec.add_development_dependency 'database_cleaner', '~> 1.4'

  spec.add_dependency 'tiny_tds',                       '~> 0.6'
  spec.add_dependency 'activerecord',                   '~> 4.1'
  spec.add_dependency 'activerecord-sqlserver-adapter', '~> 4.1'
  spec.add_dependency 'tef-core', '~> 0'
  spec.add_dependency 'tef-keeper', '~> 0'
  spec.add_dependency 'text-table', '~> 1.2'
end
