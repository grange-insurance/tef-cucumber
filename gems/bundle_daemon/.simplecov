require '../../simplecov_profiles'

SimpleCov.start do
  load_profile 'tef_basic'

  if ENV['SIMPLECOV_COVERAGE_DIR']
    SimpleCov.coverage_dir(ENV['SIMPLECOV_COVERAGE_DIR'])
  end
end
