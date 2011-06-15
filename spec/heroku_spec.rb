=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require "rubygems"
require "rspec"
require "tddium/heroku"

describe HerokuConfig do
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
        HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_return(SAMPLE_HEROKU_CONFIG_TDDIUM)
      end

      it "should return a hash of the TDDIUM config vars" do
        result = HerokuConfig.read_config
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
        HerokuConfig.stub(:`).with(cmd).and_return(SAMPLE_HEROKU_CONFIG_TDDIUM)
        HerokuConfig.should_receive(:`).with(cmd)
      end

      it "should pass the app to heroku config" do
        result = HerokuConfig.read_config(SAMPLE_APP)
        result.should_not be_nil
      end
    end

    context "missing config" do
      before do
        HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_return(SAMPLE_HEROKU_CONFIG_PARTIAL)
      end

      it "should raise InvalidFormat" do
        expect { HerokuConfig.read_config }.to raise_error(HerokuConfig::InvalidFormat)
      end
    end

    context "addon not installed" do
      before do
        HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_return(SAMPLE_HEROKU_CONFIG_NO_TDDIUM)
      end

      it "should raise NotAdded" do
        expect { HerokuConfig.read_config }.to raise_error(HerokuConfig::TddiumNotAdded)
      end
    end

    context "heroku not installed" do
      before do
        HerokuConfig.stub(:`).with(SAMPLE_HEROKU_COMMAND).and_raise(Errno::ENOENT)
      end
      it "should raise HerokuNotFound" do
        expect { HerokuConfig.read_config }.to raise_error(HerokuConfig::HerokuNotFound)
      end
    end
  end
end
