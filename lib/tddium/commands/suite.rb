=begin
Copyright (c) 2011 Solano Labs All Rights Reserved
=end

class Tddium

  desc "suite", "Register the current repo/branch, view/edit CI repos & deploy keys"
  method_option :edit, :type => :boolean, :default => false
  method_option :name, :type => :string, :default => nil
  method_option :pull_url, :type => :string, :default => nil
  method_option :push_url, :type => :string, :default => nil
  method_option :test_pattern, :type => :string, :default => nil
  def suite
    set_default_environment
    git_version_ok
    return unless git_repo? && tddium_settings

    params = {}
    begin
      if current_suite_id
        current_suite = call_api(:get, current_suite_path)["suite"]

        if options[:edit]
          update_suite(current_suite, options)
        else
          say Text::Process::EXISTING_SUITE % format_suite_details(current_suite)
        end
      else
        params[:branch] = current_git_branch
        default_suite_name = File.basename(Dir.pwd)
        params[:repo_name] = options[:name] || default_suite_name

        say Text::Process::NO_CONFIGURED_SUITE % [params[:repo_name], params[:branch]]

        use_existing_suite, existing_suite = resolve_suite_name(options, params, default_suite_name)

        if use_existing_suite
          # Write to file and exit when using the existing suite
          write_suite(existing_suite)
          say Text::Status::USING_SUITE % format_suite_details(existing_suite)
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
        write_suite(new_suite["suite"])

        say Text::Process::CREATED_SUITE % format_suite_details(new_suite["suite"])
      end
    rescue TddiumClient::Error::Base
      exit_failure
    end
  end
end
