require 'mimic'
require 'daemons'

Daemons.run_proc("mimic") do
  Mimic.mimic({:fork => false, :host => 'localhost', :port => 8080, :remote_configuration_path => '/api'}) do
  end
end
