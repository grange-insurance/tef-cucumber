require_relative 'common_tasks'


namespace 'tef' do
  namespace 'cucumber' do

    desc 'Run the migration scripts for all parts of the framework'
    task :migrate_gem_dbs, [:mode] do |t, args|

      mode = args[:mode] || 'development'

      case mode
        when 'development'
          ENV['TEF_ENV'] = 'dev'
        when 'test'
          ENV['TEF_ENV'] = 'test'
        when 'production'
          ENV['TEF_ENV'] = 'prod'
        else
          raise(ArgumentError, "Unknown mode: #{mode}")
      end

      puts "TEF env is: #{ENV['TEF_ENV']}"

      TEF::Cucumber.component_locations.each do |component, location|
        Dir.chdir(location) do
          task_name = "#{component.gsub('-', ':')}:migrate"
          file = "#{Dir.pwd}/Rakefile"

          load file

          if Rake::Task.task_defined?(task_name)
            command = "rake #{task_name}"
            puts "Migrating #{component} with: #{command}"
            system(command)
          end
        end
      end
    end

  end
end
