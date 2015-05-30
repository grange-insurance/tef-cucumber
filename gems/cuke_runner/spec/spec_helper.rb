require 'simplecov'
SimpleCov.command_name 'cuke_runner-rspec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))


here = File.dirname(__FILE__)
tef_project_location = "#{here}/../../../../tef"
require_relative "#{tef_project_location}/spec/common/specs/configured_component_unit_specs"
require_relative "#{tef_project_location}/spec/common/specs/logged_component_unit_specs"
require_relative "#{tef_project_location}/spec/common/specs/logged_component_integration_specs"


require 'cuke_runner'
