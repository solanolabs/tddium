# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class SCM
    def self.configure
      scm = nil
      [::Tddium::Git, ::Tddium::Hg].each do |scm_class|
        sniff_scm = scm_class.new
        if sniff_scm.repo? && scm_class.version_ok
          scm = sniff_scm
          break
        end
      end

      #default scm is git
      scm = ::Tddium::Git.new unless scm
      scm
    end
  end
end
