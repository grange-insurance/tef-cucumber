require_relative 'common_tasks'


namespace 'tef' do
  namespace 'cucumber' do

    desc 'Bundle install on all parts of the framework'
    task :bundle_framework, [:mode] do |t, args|
      TEF::Cucumber.component_locations.values.each do |location|
        puts "bundle installing #{location}"
        puts "with args: #{args.inspect}"

        mode = args[:mode] || 'development'

        case mode
          when 'development'
            ENV['BUNDLE_MODE'] = 'dev'
            options = '--without test production'
          when 'test'
            ENV['BUNDLE_MODE'] = 'test'
            options = '--without development production'
          when 'production'
            ENV['BUNDLE_MODE'] = 'prod'
            options = '--without development test'
          else
            raise(ArgumentError, "Unknown mode: #{mode}")
        end

        command = "bundle install #{options}"
        puts "Bundle command: #{command}"

        Dir.chdir(location) { system(command) }
      end
    end

  end
end
