# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

def load_feature_fixture(name)
  File.read(File.join(File.dirname(__FILE__), "..", "fixtures", name))
end
