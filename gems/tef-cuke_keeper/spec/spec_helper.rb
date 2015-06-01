require 'simplecov'
SimpleCov.command_name 'tef-cuke_keeper-rspec'

require 'timecop'


require 'tef/cuke_keeper'


here = File.dirname(__FILE__)
tef_project_location = "#{here}/../../../../tef"
require_relative "#{tef_project_location}/testing/mocks"
include TefTestingMocks


def tef_env
  !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
end

def tef_config
  !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'
end
