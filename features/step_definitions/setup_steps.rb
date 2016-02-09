require 'tef/development/step_definitions/setup_steps'


And(/^a configured manager node is running$/) do
  @manager_pid = Process.spawn('start "Manager" cmd /c bundle exec ruby bin/start_tef_configured_manager')
  Process.detach(@manager_pid)
end

And(/^a configured cuke keeper node is running$/) do
  @cuke_keeper_pid = Process.spawn('start "Cuke Keeper" cmd /c bundle exec ruby bin/start_tef_configured_cuke_keeper')
  Process.detach(@cuke_keeper_pid)
end

Given(/^a queuebert node is running$/) do
  @queuebert_pid = Process.spawn('start "Queuebert" cmd /c bundle exec ruby gems/tef-queuebert/bin/start_tef_queuebert')
  Process.detach(@queuebert_pid)
end

And(/^a cuke worker node is running$/) do
  @cuke_worker_pid = Process.spawn('start "Cuke Worker" cmd /c bundle exec ruby gems/tef-worker-cuke_worker/bin/start_tef_cuke_worker')
  Process.detach(@cuke_worker_pid)
end

And(/^(?:"([^"]*)" )?cuke worker nodes are running$/) do |worker_count|
  @cuke_worker_pids ||= []
  worker_count = worker_count ? worker_count.to_i : 5

  worker_count.times do
    @cuke_worker_pids << Process.spawn('start "Cuke Worker" cmd /c bundle exec ruby gems/tef-worker-cuke_worker/bin/start_tef_cuke_worker')
    Process.detach(@cuke_worker_pids.last)
  end
end

And(/^a cuke keeper node is running$/) do
  @cuke_keeper_pid = Process.spawn('start "Cuke Keeper" cmd /c bundle exec ruby gems/tef-cuke_keeper/bin/start_tef_cuke_keeper')
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

