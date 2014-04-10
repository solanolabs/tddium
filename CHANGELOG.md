# Changelog


## Version History

- v1.18.6 - Expose repository level configuration variables
- v1.18.5 - Implement further configuration validation
- v1.18.4 - Implement 'tddium find_failing' courtesy of mgrosser
- v1.18.1 - Fix shell escaping of git refs
- v1.18.0 - Support per-session ref from 'tddium run'
- v1.17.6 - 'tddium status' checks ancestor branches if current branch is not setup
- v1.17.5 - Send cache save paths (actually)
- v1.17.4 - Include more paths as default cache invalidation keys
- v1.17.3 - Fix quiet mode for `tddium run`
- v1.17.2 - Add quiet mode to `tddium run`
- v1.17.1 - Better handling of warning/error messages
- v1.17.0 - Capture cache-control metadata
- v1.16.4 - Check on current commit id when running 'tddium status'
- v1.16.3 - Ruby 2.1.0 fix
- v1.16.2 - Make `tddium describe` query the latest session on the branch by default.
- v1.16.1 - Fix `tddium status --json` to output a proper JSON document.
- v1.16.0 - encode commit data for transport reliability
- v1.15.2 - Update tddium_client to handle more error cases, update committers for preexisting session.
- v1.15.1 - Exit failure on invalid CLI arguments
- v1.15.0 - Improve performance of `tddium status`, add --json option to it.
- v1.14.1 - Update `tddium status` to work better with `tddium rerun`
- v1.13.0 - Add `tddium rerun` and `tddium describe` commands.
- v1.12.0 - Change `tddium run` to not enable CI for the suite by default (Use `tddium run --enable-ci` for the old behavior.)
- v1.11.1 - Allow `tddium suite --delete` to take the branch name as a parameter.
- v1.11.0 - Add --delete option to `tddium suite` command.  s/account/organization/g.
- v1.10.0 - Allow specifying host, port, protocol, and noverify from CLI and environment variables
- v1.9.1 - Properly route new suite creation to organizations (if the user belongs to multiple)
- v1.9.0 - Support for Tddium Organizations: http://blog.tddium.com/2013/06/09/new-feature-organizations/
- v1.8.1 - REE compatibility fixes
- v1.8.0 - Send the latest commit on session creation
- v1.7.6 - Fixes for bundler version detection
- v1.7.5 - Honor bundler_version set in tddium.yml
- v1.7.4 - Handle https repo URLs
- v1.7.3 - Fix ssh config output format.
- v1.7.2 - Re-release on github.com:solanolabs/tddium.git
