Given /^an? \w+ server on localhost:(\d+) is serving the contents of the features directory$/ do |port|
  @feature_server_pid = fork do
    ResourceServer.run! :host => 'localhost', :port => port, :root => working_dir
  end
end

After('@feature_server') do
  Process.kill('TERM', @feature_server_pid)
  Process.wait(@feature_server_pid, Process::WNOHANG)
end
