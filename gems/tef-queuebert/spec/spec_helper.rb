require 'simplecov'
SimpleCov.command_name 'tef-queuebert-rspec'

require 'json'

here = File.dirname(__FILE__)
tef_project_location = "#{here}/../../../../tef"
require_relative "#{tef_project_location}/spec/common/specs/configured_component_unit_specs"
require_relative "#{tef_project_location}/spec/common/specs/logged_component_unit_specs"
require_relative "#{tef_project_location}/spec/common/specs/logged_component_integration_specs"
require_relative "#{tef_project_location}/spec/common/specs/receiving_component_integration_specs"
require_relative "#{tef_project_location}/spec/common/specs/receiving_component_unit_specs"
require_relative "#{tef_project_location}/spec/common/specs/sending_component_integration_specs"
require_relative "#{tef_project_location}/spec/common/specs/sending_component_unit_specs"
require_relative "#{tef_project_location}/spec/common/specs/service_component_unit_specs"
require_relative "#{tef_project_location}/spec/common/specs/service_component_integration_specs"

require_relative "#{tef_project_location}/spec/common/custom_matchers"
require_relative "#{tef_project_location}/testing/fakes"
include TefTestingFakes
require_relative "#{tef_project_location}/testing/mocks"
include TefTestingMocks

require_relative 'mocks'
include TEF::TestingMocks

require 'tef/queuebert'


RSpec.configure do |config|
  config.before(:all) do

    ENV['TEF_ENV'] ||= 'dev'
    ENV['TEF_AMQP_URL_DEV'] ||= 'amqp://localhost:5672'

    @default_file_directory = "#{File.dirname(__FILE__)}/temp_files"
  end

  config.before(:each) do
    FileUtils.mkpath(@default_file_directory)
  end

  config.after(:each) do
    FileUtils.remove_dir(@default_file_directory, true)
  end

end
