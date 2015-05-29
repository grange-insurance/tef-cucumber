require 'simplecov'
SimpleCov.command_name 'tef-worker-cuke_worker-rspec'


require_relative '../../../spec/common/specs/configured_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_unit_specs'
require_relative '../../../spec/common/specs/logged_component_integration_specs'
require_relative '../../../spec/common/specs/worker_component_unit_specs'
require_relative '../../../spec/common/specs/worker_component_integration_specs'

require_relative '../../../testing/mocks'
include TefTestingMocks


require 'tef/worker/cuke_worker'


RSpec.configure do |config|
  config.before(:all) do
    @default_file_directory = "#{File.dirname(__FILE__)}/../temp_files"
  end

  config.before(:each) do
    FileUtils.mkdir(@default_file_directory)
  end

  config.after(:each) do
    FileUtils.remove_dir(@default_file_directory, true)
  end

end
