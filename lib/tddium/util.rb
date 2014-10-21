# Copyright (c) 2012, 2013, 2014 Solano Labs, Inc. All Rights Reserved

class String
  def sanitize(encoding="UTF-8")
    opts = {:invalid => :replace, :undef => :replace}
    d = self.dup
    d.force_encoding(encoding).valid_encoding? ?
      d : d.force_encoding("BINARY").encode(encoding, opts)
  end

  def sanitize!(encoding="UTF-8")
    opts = {:invalid => :replace, :undef => :replace}
    unless self.force_encoding(encoding).valid_encoding?
      self.force_encoding("BINARY")
      self.encode!(encoding, opts)
    end
  end
end

