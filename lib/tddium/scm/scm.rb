# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class SCM
    def self.configure
      scm = ::Tddium::Git.new

      [::Tddium::Git, ::Tddium::Hg].each do |scm_class|
        sniff_scm = scm_class.new
        if sniff_scm.repo? then
          scm = sniff_scm
          break
        end
      end

      scm.class.version_ok
      scm.configure
      return scm
    end
  end
end
