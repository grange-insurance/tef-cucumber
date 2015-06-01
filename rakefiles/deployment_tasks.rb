require_relative 'common_tasks'
require_relative '../../tef/rakefiles/deployment_tasks'


namespace 'tef' do

  namespace 'cucumber' do

    desc 'Spin up local versions of the Cucumber specific TEF'
    task :create_cuke_farm do

      Rake::Task['tef:cucumber:create_queuebert'].invoke
      Rake::Task['tef:create_manager'].invoke
      Rake::Task['tef:cucumber:create_cuke_worker'].invoke
      Rake::Task['tef:cucumber:create_cuke_keeper'].invoke
    end

    desc 'Spin up a local version of a queuebert'
    task :create_queuebert => [:set_environment] do
      # todo - Assuming Windows OS for the moment
      Process.spawn('start "Queuebert" cmd /c bundle exec start_tef_queuebert')
    end

    desc 'Spin up a local version of a cuke worker'
    task :create_cuke_worker => [:set_environment] do
      # todo - Assuming Windows OS for the moment
      Process.spawn('start "CukeWorker" cmd /c bundle exec start_tef_cuke_worker')
    end

    desc 'Spin up a local version of a cucumber keeper'
    task :create_cuke_keeper => [:set_environment] do
      # todo - Assuming Windows OS for the moment
      Process.spawn('start "CucumberKeeper" cmd /c bundle exec start_tef_cuke_keeper')
    end

  end
end
