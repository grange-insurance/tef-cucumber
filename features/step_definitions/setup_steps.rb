require 'tef/development/step_definitions/setup_steps'


Given(/^a queuebert node is running$/) do
  @queuebert_pid = Process.spawn('start "Queuebert" cmd /c bundle exec start_tef_queuebert')
  Process.detach(@queuebert_pid)
end

And(/^a cuke worker node is running$/) do
  @cuke_worker_pid = Process.spawn('start "Cuke Worker" cmd /c bundle exec start_tef_cuke_worker')
  Process.detach(@cuke_worker_pid)
end

And(/^(?:"([^"]*)" )?cuke worker nodes are running$/) do |worker_count|
  @cuke_worker_pids ||= []
  worker_count = worker_count ? worker_count.to_i : 5

  worker_count.times do
    @cuke_worker_pids << Process.spawn('start "Cuke Worker" cmd /c bundle exec start_tef_cuke_worker')
    Process.detach(@cuke_worker_pids.last)
  end
end

And(/^a cuke keeper node is running$/) do
  @cuke_keeper_pid = Process.spawn('start "Cuke Keeper" cmd /c bundle exec start_tef_cuke_keeper')
  Process.detach(@cuke_keeper_pid)
end
