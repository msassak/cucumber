Given /^an? \w+ server on localhost:(\d+) is serving the contents of the features directory$/ do |port|
  @resource_server_pid = fork do
    ResourceServer.run! :host => 'localhost', :port => port, :root => working_dir
  end
end

After('@resource_server') do
  Process.kill('TERM', @resource_server_pid)
  Process.wait(@resource_server_pid, Process::WNOHANG)
end
