# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

module Tddium
  class TddiumCli < Thor
    desc "suite", "Register the current repo/branch, view/edit CI repos & deploy keys"
    method_option :edit, :type => :boolean, :default => false
    method_option :name, :type => :string, :default => nil
    method_option :repo_url, :type => :string, :default => nil
    method_option :ci_pull_url, :type => :string, :default => nil
    method_option :ci_push_url, :type => :string, :default => nil
    method_option :test_pattern, :type => :string, :default => nil
    method_option :campfire_room, :type => :string, :default => nil
    method_option :hipchat_room, :type => :string, :default => nil
    method_option :non_interactive, :type => :boolean, :default => false
    method_option :tool, :type => :hash, :default => {}
    def suite
      tddium_setup({:repo => true})

      params = {}

      # Load tool options into params
      tool_cli_populate(options, params)

      begin

        if @tddium_api.current_suite_id then
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
          params[:branch] = Tddium::Git.git_current_branch
          params[:repo_url] = Tddium::Git.git_origin_url
          params[:repo_name] = Tddium::Git.git_repo_name

          say Text::Process::NO_CONFIGURED_SUITE % [params[:repo_name], params[:branch]]

          existing_suite = lookup_suite(options, params[:repo_url], params[:branch])

          if existing_suite then
            # Write to file and exit when using the existing suite
            say Text::Process::FOUND_EXISTING_SUITE % [params[:repo_url], params[:branch]]
            @api_config.set_suite(existing_suite)
            @api_config.write_config
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
