# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli
    desc "suite", "Register the current repo/branch, view/edit CI repos & deploy keys"
    method_option :edit, :type => :boolean, :default => false
    method_option :name, :type => :string, :default => nil
    method_option :ci_pull_url, :type => :string, :default => nil
    method_option :ci_push_url, :type => :string, :default => nil
    method_option :test_pattern, :type => :string, :default => nil
    method_option :campfire_room, :type => :string, :default => nil
    method_option :hipchat_room, :type => :string, :default => nil
    method_option :non_interactive, :type => :boolean, :default => false
    def suite
      set_default_environment
      git_version_ok
      exit_failure unless tddium_settings && git_repo?

      params = {}
      begin
        if current_suite_id
          current_suite = call_api(:get, current_suite_path)["suite"]

          if options[:edit]
            update_suite(current_suite, options)
          else
            say Text::Process::EXISTING_SUITE, :bold
            say format_suite_details(current_suite)
          end
        else
          params[:branch] = current_git_branch
          default_suite_name = File.basename(git_root)
          params[:repo_name] = options[:name] || default_suite_name

          say Text::Process::NO_CONFIGURED_SUITE % [params[:repo_name], params[:branch]]

          use_existing_suite, existing_suite = suite_resolve_name(options, params, default_suite_name)

          if use_existing_suite
            # Write to file and exit when using the existing suite
            tddium_write_suite(existing_suite)
            say Text::Status::USING_SUITE, :bold
            say format_suite_details(existing_suite)
            return
          end

          prompt_suite_params(options, params)

          params.each do |k,v|
            params.delete(k) if v == 'disable'
          end

          # Create new suite if it does not exist yet
          say Text::Process::CREATING_SUITE % [params[:repo_name], params[:branch]]
          new_suite = call_api(:post, Api::Path::SUITES, {:suite => params})
          # Save the created suite
          tddium_write_suite(new_suite["suite"])

          say Text::Process::CREATED_SUITE, :bold
          say format_suite_details(new_suite["suite"])
        end
      rescue TddiumClient::Error::Base
        exit_failure
      end
    end
  end
end
