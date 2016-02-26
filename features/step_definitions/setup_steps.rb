require 'tef/development/step_definitions/setup_steps'


And(/^a local configured manager node is running$/) do
  here = File.dirname(__FILE__)
  path_to_manager_binary = "#{here}/../../bin/start_tef_configured_manager"

  # todo - Assuming Windows OS for the moment
  @manager_pid = Process.spawn("start \"Manager\" cmd /c bundle exec ruby #{path_to_manager_binary}")
  Process.detach(@manager_pid)
end

And(/^a local configured cuke keeper node is running$/) do
  here = File.dirname(__FILE__)
  path_to_keeper_binary = "#{here}/../../bin/start_tef_configured_cuke_keeper"

  # todo - Assuming Windows OS for the moment
  @cuke_keeper_pid = Process.spawn("start \"Cuke Keeper\" cmd /c bundle exec ruby #{path_to_keeper_binary}")
  Process.detach(@cuke_keeper_pid)
end

Given(/^a local queuebert node is running$/) do
  here = File.dirname(__FILE__)
  path_to_queuebert_binary = "#{here}/../../gems/tef-queuebert/bin/start_tef_queuebert"

  # todo - Assuming Windows OS for the moment
  @queuebert_pid = Process.spawn("start \"Queuebert\" cmd /c bundle exec ruby #{path_to_queuebert_binary}")
  Process.detach(@queuebert_pid)
end

And(/^a local cuke worker node is running$/) do
  here = File.dirname(__FILE__)
  path_to_worker_binary = "#{here}/../../gems/tef-worker-cuke_worker/bin/start_tef_cuke_worker"

  # todo - Assuming Windows OS for the moment
  @cuke_worker_pid = Process.spawn("start \"Cuke Worker\" cmd /c bundle exec ruby #{path_to_worker_binary}")
  Process.detach(@cuke_worker_pid)
end

And(/^(?:"([^"]*)" )?local cuke worker nodes are running$/) do |worker_count|
  here = File.dirname(__FILE__)
  path_to_worker_binary = "#{here}/../../gems/tef-worker-cuke_worker/bin/start_tef_cuke_worker"

  @cuke_worker_pids ||= []
  worker_count = worker_count ? worker_count.to_i : 5

  worker_count.times do
    # todo - Assuming Windows OS for the moment
    @cuke_worker_pids << Process.spawn("start \"Cuke Worker\" cmd /c bundle exec ruby #{path_to_worker_binary}")
    Process.detach(@cuke_worker_pids.last)
  end
end

And(/^a local cuke keeper node is running$/) do
  here = File.dirname(__FILE__)
  path_to_keeper_binary = "#{here}/../../gems/tef-cuke_keeper/bin/start_tef_cuke_keeper"

  # todo - Assuming Windows OS for the moment
  @cuke_keeper_pid = Process.spawn("start \"Cuke Keeper\" cmd /c bundle exec ruby #{path_to_keeper_binary}")
  Process.detach(@cuke_keeper_pid)
end


And(/^all components have finished starting up$/) do
  # Every component's message queue needs to exist
  queuebert_queue_name = "tef.#{@tef_env}.queuebert.request"
  wait_for { puts "Waiting for queue #{queuebert_queue_name} to be available..."; @bunny_connection.queue_exists?(queuebert_queue_name) }.to be true
  manager_queue_name = "tef.#{@tef_env}.manager"
  wait_for { puts "Waiting for queue #{manager_queue_name} to be available..."; @bunny_connection.queue_exists?(manager_queue_name) }.to be true
  keeper_queue_name = "tef.#{@tef_env}.keeper.cucumber"
  wait_for { puts "Waiting for queue #{keeper_queue_name} to be available..."; @bunny_connection.queue_exists?(keeper_queue_name) }.to be true

  # And have a moment to hook them all up to exchanges
  sleep 1
end

