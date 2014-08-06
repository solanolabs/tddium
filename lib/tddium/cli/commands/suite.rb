# Copyright (c) 2011, 2012, 2013, 2014 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "suite", "Register the current repo/branch, view/edit CI repos & deploy keys"
    method_option :edit, :type => :boolean, :default => false
    method_option :account, :type => :string, :default => nil,
      :aliases => %w(--org --organization)
    method_option :name, :type => :string, :default => nil
    method_option :repo_url, :type => :string, :default => nil
    method_option :ci_pull_url, :type => :string, :default => nil
    method_option :ci_push_url, :type => :string, :default => nil
    method_option :test_pattern, :type => :string, :default => nil
    method_option :campfire_room, :type => :string, :default => nil
    method_option :hipchat_room, :type => :string, :default => nil
    method_option :non_interactive, :type => :boolean, :default => false
    method_option :tool, :type => :hash, :default => {}
    method_option :delete, :type => :boolean, :default => false
    def suite(*argv)
      tddium_setup({:repo => true})

      params = {}

      # Load tool options into params
      tool_cli_populate(options, params)

      begin

        if options[:delete]
          # Deleting works differently (for now) because api_config can't handle
          # multiple suites with the same branch name in two different accounts.

          repo_url = @scm.origin_url

          if argv.is_a?(Array) && argv.size > 0
            branch = argv[0]
          else
            branch = @tddium_api.current_branch
          end

          suites = @tddium_api.get_suites(:repo_url => repo_url, :branch => branch)
          if suites.count == 0
            exit_failure Text::Error::CANT_FIND_SUITE % [repo_url, branch]
          elsif suites.count > 1
            say Text::Process::SUITE_IN_MULTIPLE_ACCOUNTS % [repo_url, branch]
            suites.each { |s| say '  ' + s['account'] }
            account = ask Text::Process::SUITE_IN_MULTIPLE_ACCOUNTS_PROMPT
            suites = suites.select { |s| s['account'] == account }
            if suites.count == 0
              exit_failure Text::Error::INVALID_ACCOUNT_NAME
            end
          end

          suite = suites.first

          unless options[:non_interactive]
            yn = ask Text::Process::CONFIRM_DELETE_SUITE % [suite['repo_url'], suite['branch'], suite['account']]
            unless yn.downcase == Text::Prompt::Response::YES
              exit_failure Text::Process::ABORTING
            end
          end

          @tddium_api.permanent_destroy_suite(suite['id'])
          @api_config.delete_suite(suite['branch'])
          @api_config.write_config

        elsif @tddium_api.current_suite_id then
          # Suite ID set in tddium config file
          current_suite = @tddium_api.get_suite_by_id(@tddium_api.current_suite_id)
          if options[:edit] then
            update_suite(current_suite, options)
          else
            say Text::Process::EXISTING_SUITE, :bold
            say format_suite_details(current_suite)
          end

          @api_config.set_suite(current_suite)
          @api_config.write_config
        else
          # Need to find or construct the suite (and repo)
          params[:branch] = @scm.current_branch
          params[:repo_url] = @scm.origin_url
          params[:repo_name] = @scm.repo_name
          params[:scm] = @scm.scm_name

          say Text::Process::NO_CONFIGURED_SUITE % [params[:repo_name], params[:branch]]

          prompt_suite_params(options, params)

          params.each do |k,v|
            params.delete(k) if v == 'disable'
          end

          # Create new suite if it does not exist yet
          say Text::Process::CREATING_SUITE % [params[:repo_name], params[:branch]]
          new_suite = @tddium_api.create_suite(params)

          # Save the created suite
          @api_config.set_suite(new_suite)
          @api_config.write_config

          say Text::Process::CREATED_SUITE, :bold
          say format_suite_details(new_suite)
        end
      rescue TddiumClient::Error::Base => e
        exit_failure(e)
      end
    end
  end
end
