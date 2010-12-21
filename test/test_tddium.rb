require 'helper'

class TestTddium < Test::Unit::TestCase
  context "executable" do
    setup do
      @tddium = TDDium.new
    end

    should "have a run! method" do
      assert @tddium.respond_to?(:run!)
    end

    should "return exit code from run!" do
      assert @tddium.run!.is_a? Integer
    end
  end
      
  context "prompt the user for configuration" do
    should "ask for AWS access key"
    should "ask for AWS secret"
  end
  context "save configuration" do
    should "write ~/.tddium"
  end
  context "read configuration" do
    should "read AWS access key"
    should "read AWS secret key"
  end
  context "create instance" do
    should "create instance from tddium AMI"
    should "start services on instance"
  end
  context "run selenium with created instance" do
    should "set SELENIUM_REMOTE_HOST environment variable"
    should "run spec rake task"
    should "save selenium report to unique folder"
  end
  should "stop created instance"
end
