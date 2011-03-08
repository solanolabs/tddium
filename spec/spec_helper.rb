require "tddium"
require "fakeweb"
require "rack/test"
require "fakefs/spec_helpers"
FakeWeb.allow_net_connect = false

def fixture_path(fixture_name)
  File.join File.dirname(__FILE__), "fixtures", fixture_name
end