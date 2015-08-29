require_relative 'common_tasks'


namespace 'tef' do
  namespace 'cucumber' do

    desc 'Build all gems'
    task :build_gems do
      @built_gems = []

      TEF::Cucumber.component_locations.each do |component, location|
        next unless location =~ /^gems/

        puts "Building gem #{component} from #{location}"
        Dir.chdir(location) do
          output = IO.popen("gem build #{component}.gemspec").read
          gem_file = output[/#{component}.*\.gem/]

          @built_gems << "#{location}/#{gem_file}"
        end
      end
    end

    desc 'Install all gems'
    task :install_gems, [:install_options] => [:build_gems] do |t, args|
      @built_gems.each do |gem_file|
        command = "gem install #{gem_file}"
        command += " #{args[:install_options]}" if args[:install_options]

        puts "Installing gem at #{gem_file}"
        puts "with command: #{command}"

        system(command)
      end
    end

  end
end
