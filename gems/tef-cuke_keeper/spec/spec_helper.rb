require 'simplecov'
SimpleCov.command_name 'tef-cuke_keeper-rspec'

require 'timecop'


require 'tef/cuke_keeper'


require 'tef/development/testing/mocks'
include TEF::Development::Testing::Mocks



def tef_env
  !ENV['TEF_ENV'].nil? ? ENV['TEF_ENV'].downcase : 'dev'
end

def tef_config
  !ENV['TEF_CONFIG'].nil? ? ENV['TEF_CONFIG'] : './config'
end
