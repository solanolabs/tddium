=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

require "rubygems"
require "rspec"
require "tddium/heroku"

describe HerokuConfig do
  SAMPLE_HEROKU_CONFIG_TDDIUM = "
TDDIUM_API_KEY=abcdefg
TDDIUM_USER_NAME=app1234@heroku.com
"
  SAMPLE_HEROKU_CONFIG_NO_TDDIUM = "
DB_URL=postgres://foo/bar
"
  describe ".read_config" do
    context "addon installed" do
      before do
        HerokuConfig.stub(:`).with("heroku config -s").and_return(SAMPLE_HEROKU_CONFIG_TDDIUM)
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

    context "addon not installed" do
      before do
        HerokuConfig.stub(:`).with("heroku config -s").and_return(SAMPLE_HEROKU_CONFIG_NO_TDDIUM)
      end

      it "should return nil" do
        HerokuConfig.read_config.should be_nil
      end
    end

    context "heroku not installed" do
      before do
        HerokuConfig.stub(:`).with("heroku config -s").and_raise(Errno::ENOENT)
      end
      it "should return nil" do
        HerokuConfig.read_config.should be_nil
      end
    end
  end
end
