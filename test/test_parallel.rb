require 'helper'
require 'mocha'
require 'fakefs'
require 'tddium/parallel'

class TestParallel < Test::Unit::TestCase
  context "make_spec_cmd" do
    should "raise if no result_path specified" do
      assert_raise RuntimeError do
        make_spec_cmd([1], 'a', nil)
      end
    end
    should "suppress RSPEC_COLOR if stdout is not tty" do
      $stdout.stubs(:tty? => false)
      assert_no_match /RSPEC_COLOR/, make_spec_cmd(['a'], 'a', 'a')
    end
  end

  context "test_batches" do
    setup do
      @config = {:test_pattern => '*.rb'}
      stubs(:read_config => @config)
      @files = %w{a b c d e}
      @files.each { |f| File.open("#{f}.rb", 'w') { |o| o.write('a') } }
    end
    should "find batches" do
      [1,2,3,4,5,6].each do |n|
        b = test_batches(n)
        assert_equal n, b.size
      end
    end
  end

  context "parallel_task" do
    setup do
      @batches = [['a', 'b'], ['c']]
      stubs(:test_batches => @batches)
      stubs(:execute_command => 'a')
    end
    should "run with defaults" do
      args = mock()
      args.expects(:with_defaults)
      args.stubs(:threads => 5, :inspect => 'args', :environment => 'selenium')
      parallel_task(args)
    end
  end
end
