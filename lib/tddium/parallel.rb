require 'parallel'
require 'tddium/config'

def parallel_task(args)
  args.with_defaults(:threads => 2, :environment => "selenium")

  STDERR.puts args.inspect

  tests = find_test_files
  STDERR.puts "\t#{tests.size} test files"

  environ = { 
    "RAILS_ENV" => args.environment,
    'RSPEC_COLOR' => $stdout.tty? ? 1 : nil
  }

  env_str = environ.map{|k,v| "#{k}=#{v}"}.join(' ')

  output = {}

  until tests.empty?
    Parallel.in_threads(args.threads.to_i) do |i|
      test = tests.shift
      if test
        cmd = "env #{env_str} "
        cmd << "spec"
        cmd << '--color'
        cmd << "--require 'rubygems,selenium/rspec/reporting/selenium_test_report_formatter'"
        cmd << "--format=Selenium::RSpec::SeleniumTestReportFormatter:#{$result_path}"
        cmd << "--format=progress"                
        cmd << "#{test}"
        output.merge!({"#{test}" => execute_command( cmd )})
        #puts "Running results: #{output.inspect}"
      end
    end
  end

  output.each do |key, value|
    puts ">>>>>>>> #{key}"
    puts value
  end
end

def self.execute_command(cmd)
  STDERR.puts "Running '#{cmd}'"
  return
  f = open("|#{cmd}")
  all = ''
  while out = f.gets(".")
    all+=out
    print out
    STDOUT.flush
  end
  all
end
