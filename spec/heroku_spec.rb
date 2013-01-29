# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require "rubygems"
require "rspec"
require "tddium/heroku"

describe Tddium::HerokuConfig do
  SAMPLE_APP = "testapp"
  SAMPLE_HEROKU_CONFIG_TDDIUM = "
TDDIUM_API_KEY=abcdefg
TDDIUM_USER_NAME=app1234@heroku.com
"
  SAMPLE_HEROKU_CONFIG_PARTIAL = "
TDDIUM_API_KEY=abcdefg
"
  SAMPLE_HEROKU_CONFIG_NO_TDDIUM = "
DB_URL=postgres://foo/bar
"
  SAMPLE_HEROKU_COMMAND = "heroku config -s < /dev/null 2>&1"
  describe ".read_config" do
    context "addon installed" do
      before do
        Tddium::HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_return(SAMPLE_HEROKU_CONFIG_TDDIUM)
      end

      it "should return a hash of the TDDIUM config vars" do
        result = Tddium::HerokuConfig.read_config
        result.should be_a(Hash)
        result.each do |k,v|
          k.should =~ /^TDDIUM_/
          v.length.should > 0
        end
        result.should include('TDDIUM_API_KEY')
        result['TDDIUM_API_KEY'].should == 'abcdefg'
      end
    end

    context "with app specified" do
      before do
        cmd = "heroku config -s --app #{SAMPLE_APP} < /dev/null 2>&1"
        Tddium::HerokuConfig.stub(:`).with(cmd).and_return(SAMPLE_HEROKU_CONFIG_TDDIUM)
        Tddium::HerokuConfig.should_receive(:`).with(cmd)
      end

      it "should pass the app to heroku config" do
        result = Tddium::HerokuConfig.read_config(SAMPLE_APP)
        result.should_not be_nil
      end
    end

    context "missing config" do
      before do
        Tddium::HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_return(SAMPLE_HEROKU_CONFIG_PARTIAL)
      end

      it "should raise InvalidFormat" do
        expect { Tddium::HerokuConfig.read_config }.to raise_error(Tddium::HerokuConfig::InvalidFormat)
      end
    end

    context "addon not installed" do
      before do
        Tddium::HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_return(SAMPLE_HEROKU_CONFIG_NO_TDDIUM)
      end

      it "should raise NotAdded" do
        expect { Tddium::HerokuConfig.read_config }.to raise_error(Tddium::HerokuConfig::TddiumNotAdded)
      end
    end

    context "heroku not installed" do
      before do
        Tddium::HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_raise(Errno::ENOENT)
      end
      it "should raise HerokuNotFound" do
        expect { Tddium::HerokuConfig.read_config }.to raise_error(Tddium::HerokuConfig::HerokuNotFound)
      end
    end
  end
end
