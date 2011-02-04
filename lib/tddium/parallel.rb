require 'parallel'
require 'tddium/config'

def make_spec_cmd(testname, environment, result_path)
  if !result_path
    raise "result_path must be specified"
  end

  environ = { 
    "RAILS_ENV" => environment,
    'RSPEC_COLOR' => $stdout.tty? ? 1 : nil
  }

  env_str = environ.map{|k,v| "#{k}=#{v}" if v}.join(' ')
  cmd = "env #{env_str} "
  cmd << "spec "
  cmd << '--color '
  cmd << "--require 'rubygems,selenium/rspec/reporting/selenium_test_report_formatter' "
  cmd << "--format=Selenium::RSpec::SeleniumTestReportFormatter:#{result_path} "
  cmd << "--format=progress "                
  cmd << "#{testname} "
  cmd
end

def parallel_task(args)
  args.with_defaults(:threads => 2, :environment => "selenium")

  STDERR.puts args.inspect

  tests = find_test_files
  STDERR.puts "\t#{tests.size} test files"

  latest = result_directory
  puts "Running tests. Results will be in #{latest}"

  output = {}

  until tests.empty?
    Parallel.in_threads(args.threads.to_i) do |i|
      testname = tests.shift
      if testname
        result_path = File.join(latest, "#{i}-#{REPORT_FILENAME}")
        cmd = make_spec_cmd(testname, args.environment, result_path)
        output.merge!({"#{testname}" => execute_command( cmd )})
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
  f = open("|#{cmd}")
  all = ''
  while out = f.gets(".")
    all+=out
    print out
    STDOUT.flush
  end
  all
end
