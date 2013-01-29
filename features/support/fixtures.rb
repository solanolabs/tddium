# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

def load_feature_fixture(name)
  File.read(File.join(File.dirname(__FILE__), "..", "fixtures", name))
end
