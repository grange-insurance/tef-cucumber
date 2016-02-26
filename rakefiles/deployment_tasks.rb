require_relative 'common_tasks'
require 'tef/development/deployment_tasks'


namespace 'tef' do

  namespace 'cucumber' do

    desc 'Spin up local versions of the Cucumber specific TEF'
    task :create_cuke_farm do
      Rake::Task['tef:create_manager'].invoke
      Rake::Task['tef:cucumber:create_queuebert'].invoke
      Rake::Task['tef:cucumber:create_cuke_worker'].invoke
      Rake::Task['tef:cucumber:create_cuke_keeper'].invoke
    end

    desc 'Spin up a manager from the current source code'
    task :create_manager => [:set_tef_environment] do
      here = File.dirname(__FILE__)
      path_to_manager_binary = "#{here}/../bin/start_tef_configured_manager"

      # todo - Assuming Windows OS for the moment
      Process.spawn("start \"Manager\" cmd /c bundle exec ruby #{path_to_manager_binary}")
    end

    desc 'Spin up a queuebert from the current source code'
    task :create_queuebert => [:set_tef_environment] do
      here = File.dirname(__FILE__)
      path_to_queuebert_binary = "#{here}/../gems/tef-queuebert/bin/start_tef_queuebert"

      # todo - Assuming Windows OS for the moment
      Process.spawn("start \"Queuebert\" cmd /c bundle exec ruby #{path_to_queuebert_binary}")
    end

    desc 'Spin up a cuke worker from the current source code'
    task :create_cuke_worker => [:set_tef_environment] do
      here = File.dirname(__FILE__)
      path_to_worker_binary = "#{here}/../gems/tef-worker-cuke_worker/bin/start_tef_cuke_worker"

      # todo - Assuming Windows OS for the moment
      Process.spawn("start \"CukeWorker\" cmd /c bundle exec ruby #{path_to_worker_binary}")
    end

    desc 'Spin up a cucumber keeper from the current source code'
    task :create_cuke_keeper => [:set_tef_environment] do
      here = File.dirname(__FILE__)
      path_to_keeper_binary = "#{here}/../bin/start_tef_configured_cuke_keeper"

      # todo - Assuming Windows OS for the moment
      Process.spawn("start \"CucumberKeeper\" cmd /c bundle exec ruby #{path_to_keeper_binary}")
    end

  end
end
