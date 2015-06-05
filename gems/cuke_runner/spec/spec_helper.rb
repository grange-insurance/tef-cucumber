require 'simplecov'
SimpleCov.command_name 'cuke_runner-rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))


require 'tef/development/specs/configured_component_unit_specs'
require 'tef/development/specs/logged_component_unit_specs'
require 'tef/development/specs/logged_component_integration_specs'


require 'cuke_runner'
