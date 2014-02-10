# Copyright (c) 2011, 2012, 2013 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "github:migrate_hooks", "Authorize and switche the repo to use the tddium webhook with the proper token"
    define_method "github:migrate_hooks" do
      suites = @tddium_api.get_suites
      if suites.any?
        say 'Please enter your github credentials, we do not store them anywhere'
        username = HighLine.ask("username: ")
        password = HighLine.ask("password: "){ |q| q.echo = "*" }
        @github = Github.new(login: username, password: password)
        
        suites.each do |suite|
          login = suite.org_name || username
          unless has_hook_token?(suite, login)
            if confirm_for_repo?(suite.repo_name)
              set_hook_token(suite, login)
            end
          end
        end
      else
        say "You have no any configured repos on tddium site."
      end
    end

    private

    def has_hook_token?(suite, login)
      @github.repos.hooks.list(login, suite.repo_name).any? do |hook|
         hook["config"].try(:[], "token") == suite.repo_ci_hook_key && hook["active"]
      end
    end

    def confirm_for_repo?(name)
      msg = "Do you want to switch the repo '#{name}' to use the tddium webhook with the proper token? (Yes/No/All)"
      (@prev && @prev == 'All') || 
      ((@prev = HighLine.ask(msg){ |q| q.validate = /Yes|No|All/ }) && ['Yes','All'].include?(@prev))
    end

    def set_hook_token(suite, login)
      @github.repos.hooks.create(login, suite.repo_name, {
        active: true,
        name:   :tddium,
        config: { 
          token: suite.repo_ci_hook_key 
        }
      })
    end
  end
end
