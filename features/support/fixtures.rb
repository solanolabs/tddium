# Copyright (c) 2011 Solano Labs, Inc.  All Rights Reserved.

def load_feature_fixture(name)
  File.read(File.join(File.dirname(__FILE__), "..", "fixtures", name))
end
