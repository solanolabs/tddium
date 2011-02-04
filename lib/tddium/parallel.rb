require 'parallel'
require 'tddium/config'

def make_spec_cmd(tests, environment, result_path)
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
  cmd << "#{tests.join(' ')} "
  cmd
end

def test_batches(num_batches)
  tests = find_test_files
  STDERR.puts "\t#{tests.size} test files"

  chunk_size = tests.size / num_batches
  remainder = tests.size % num_batches
  batches = []
  num_batches.times do |c|
    if c < remainder
      batches << tests[((c*chunk_size)+c),(chunk_size+1)]
    else
      batches << tests[((c*chunk_size)+remainder),chunk_size]
    end
  end
  
  STDERR.puts batches.inspect
  batches
end

def parallel_task(args)
  args.with_defaults(:threads => 5, :environment => "selenium")
  threads = args.threads.to_i

  STDERR.puts args.inspect

  latest = result_directory
  puts "Running tests. Results will be in #{latest}"

  output = {}

  batches = test_batches(threads)

  Parallel.in_threads(threads) do |i|
    if batches[i]
      result_path = File.join(latest, "#{i}-#{REPORT_FILENAME}")
      cmd = make_spec_cmd(batches[i], args.environment, result_path)
      output.merge!({"#{batches[i].inspect}" => execute_command( cmd )})
      #puts "Running results: #{output.inspect}"
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
