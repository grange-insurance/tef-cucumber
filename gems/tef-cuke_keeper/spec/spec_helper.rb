require 'simplecov'
SimpleCov.command_name 'tef-cuke_keeper-rspec'


require 'tef/cuke_keeper'

require_relative '../../../testing/mocks'
include TefTestingMocks


def tef_env
  !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
end

def tef_config
  !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'
end
