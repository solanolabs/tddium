require 'mimic'
require 'daemons'

class MimicServer
  attr_reader :port

  def initialize
    @port = 8080
    @pid_dir = '/tmp/mimic'
    FileUtils.mkdir_p('/tmp/mimic')
  end

  def start
    options = {:ARGV => ['start'], :dir_mode => :normal, :dir => @pid_dir}
    args = {:fork => false,
            :host => 'localhost',
            :port => @port,
            :remote_configuration_path => '/api'}
    @mimic_group = Daemons.run_proc("mimic", options) do
      Mimic.mimic(args) do
      end
    end
  end

  def stop
    @mimic_group.stop_all
    @mimic_group.find_applications(@pid_dir)
    @mimic_group.zap_all
  end
end
