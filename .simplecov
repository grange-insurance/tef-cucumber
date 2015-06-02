require 'tef/development/simplecov_profiles'

SimpleCov.start do
  load_profile 'tef_basic'

  # Redirecting component code coverage results to a common location
  ENV['SIMPLECOV_COVERAGE_DIR'] = "#{File.dirname(__FILE__)}/coverage"

  SimpleCov.command_name 'TEF'
end
