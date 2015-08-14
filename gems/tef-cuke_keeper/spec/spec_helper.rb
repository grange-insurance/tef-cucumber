require 'simplecov'
SimpleCov.command_name 'tef-cuke_keeper-rspec'

require 'timecop'


require 'tef/cuke_keeper'


require 'tef/development/testing/mocks'
include TEF::Development::Testing::Mocks
require 'helper_methods'


def tef_env
  !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
end

def tef_config
  !ENV['TEF_CUKE_KEEPER_DB_CONFIG'].nil? ? ENV['TEF_CUKE_KEEPER_DB_CONFIG'] : './config'
end
