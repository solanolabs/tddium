# Copyright (c) 2011, 2012 Solano Labs All Rights Reserved

require 'aruba/api'

SAMPLE_API_KEY = "afb12412bdafe124124asfasfabebafeabwbawf1312342erbfasbb"
SAMPLE_APP_NAME = "tddelicious"
SAMPLE_REPO_URL = "git@github.com:user/repo.git"
SAMPLE_BRANCH_NAME = "test"
SAMPLE_BUNDLER_VERSION = "Bundler version 1.10.10"
SAMPLE_DATE_TIME = "2011-03-11T08:43:02Z"
SAMPLE_EMAIL = "someone@example.com"
SAMPLE_FILE_PATH = "./my_user_file.png"
SAMPLE_FILE_PATH2 = "./my_user_file2.png"
SAMPLE_INVITATION_TOKEN = "TZce3NueiXp2lMTmaeRr"
SAMPLE_HEROKU_CONFIG = {"TDDIUM_API_KEY" => SAMPLE_API_KEY, "TDDIUM_USER_NAME" => SAMPLE_EMAIL}
SAMPLE_LICENSE_TEXT = "LICENSE"
SAMPLE_PASSWORD = "foobar"
SAMPLE_NEW_PASSWORD = "foobar2"
SAMPLE_REPORT_URL = "http://api.tddium.com/1/sessions/1/test_executions/report"
SAMPLE_RUBYGEMS_VERSION = "1.3.7"
SAMPLE_RUBY_VERSION = "ruby 1.8.7 (2010-08-16 patchlevel 302) [i686-darwin10.5.0]"
SAMPLE_RECURLY_URL = "https://tddium.recurly.com/account/1"
SAMPLE_SESSION_ID = 1
SAMPLE_SUITE_ID = 1
SAMPLE_REPO_ID = 1
SAMPLE_USER_ID = 1
SAMPLE_ACCOUNT_ID = 1
SAMPLE_ROLE = "member"
SAMPLE_ACCOUNT_NAME = "owner@example.com"
DEFAULT_TEST_PATTERN = "**/*_spec.rb"
SAMPLE_SUITE_PATTERN = "features/*.feature, spec/**/*_spec.rb"
CUSTOM_TEST_PATTERN = "**/cat_spec.rb"
SAMPLE_SSH_PUBKEY = "ssh-rsa 1234567890"
SAMPLE_SUITE_RESPONSE = {"repo_name" => SAMPLE_APP_NAME,
                         "repo_url" => SAMPLE_REPO_URL,
                         "branch" => SAMPLE_BRANCH_NAME, 
                         "id" => SAMPLE_SUITE_ID, 
                         "ruby_version"=>SAMPLE_RUBY_VERSION,
                         "rubygems_version"=>SAMPLE_RUBYGEMS_VERSION,
                         "bundler_version"=>SAMPLE_BUNDLER_VERSION,
                         "ci_ssh_pubkey" => SAMPLE_SSH_PUBKEY,
                         "test_pattern" => SAMPLE_SUITE_PATTERN}
SAMPLE_SUITES_RESPONSE = {"suites" => [SAMPLE_SUITE_RESPONSE]}
SAMPLE_TDDIUM_CONFIG_FILE = ".tddium.test"
SAMPLE_TDDIUM_DEPLOY_KEY_FILE = ".tddium-deploy-key.test"
SAMPLE_TEST_EXECUTION_STATS = "total 1, notstarted 0, started 1, passed 0, failed 0, pending 0, error 0", "start_time"
SAMPLE_USER_RESPONSE = {"status"=>0, "user"=>
  { "id"=>SAMPLE_USER_ID, 
    "api_key" => SAMPLE_API_KEY, 
    "email" => SAMPLE_EMAIL, 
    "created_at" => SAMPLE_DATE_TIME, 
    "account" => SAMPLE_EMAIL,
    "account_id" => SAMPLE_ACCOUNT_ID,
    "recurly_url" => SAMPLE_RECURLY_URL}}
SAMPLE_THIRD_PARTY_PUBKEY = "ABCDEF"
SAMPLE_USER_THIRD_PARTY_KEY_RESPONSE = {"status"=>0, "user"=>
  { "id"=>SAMPLE_USER_ID, 
    "api_key" => SAMPLE_API_KEY, 
    "email" => SAMPLE_EMAIL, 
    "created_at" => SAMPLE_DATE_TIME, 
    "account" => SAMPLE_EMAIL,
    "recurly_url" => SAMPLE_RECURLY_URL,
    "third_party_pubkey" => SAMPLE_THIRD_PARTY_PUBKEY}}
SAMPLE_ADDED_USER_RESPONSE = {"status"=>0, "user"=>
  { "id"=>SAMPLE_USER_ID, 
    "api_key" => SAMPLE_API_KEY, 
    "email" => SAMPLE_EMAIL, 
    "created_at" => SAMPLE_DATE_TIME, 
    "account" => SAMPLE_ACCOUNT_NAME,
    "account_role" => SAMPLE_ROLE}}
SAMPLE_HEROKU_USER_RESPONSE = {"status"=>0, "user"=>
  { "id"=>SAMPLE_USER_ID, 
    "api_key" => "apikey", 
    "email" => SAMPLE_EMAIL, 
    "created_at" => SAMPLE_DATE_TIME, 
    "heroku_needs_activation" => true,
    "recurly_url" => SAMPLE_RECURLY_URL}}
PASSWORD_ERROR_EXPLANATION = "bad confirmation"
PASSWORD_ERROR_RESPONSE = {"status"=>1, "explanation"=> PASSWORD_ERROR_EXPLANATION}
SAMPLE_ACCOUNT_USAGE = {"status"=>0, "usage"=>"Usage: something"}
SAMPLE_CHECK_DONE_RESPONSE = {"status"=>0, "done"=>true, "session_status"=>"passed"}
SAMPLE_MESSAGE_ENTRY = {"level"=>"notice", "text"=>"abcdef    ", "seqno"=>1}
SAMPLE_WARNING_MESSAGE_ENTRY = {"level"=>"warn", "text"=>"abcdef    ", "seqno"=>1}
SAMPLE_START_TEST_EXECUTIONS_RESPONSE = {"status"=>0, "started"=>4, "report"=>SAMPLE_REPORT_URL}
SAMPLE_TEST_EXECUTIONS_PASSED_RESPONSE = {
  "status"=>0,
  "report"=>SAMPLE_REPORT_URL,
  "session_status"=>"passed",
  "session_done"=>true,
  "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/pig_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/dog_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}}
SAMPLE_TEST_EXECUTIONS_FAILED_RESPONSE = {
  "status"=>0,
  "report"=>SAMPLE_REPORT_URL,
  "session_status"=>"failed",
  "session_done"=>true,
  "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"failed"},
            "spec/pig_spec.rb"=>{"finished" => true, "status"=>"failed"},
            "spec/dog_spec.rb"=>{"finished" => true, "status"=>"failed"},
            "spec/cat_spec.rb"=>{"finished" => true, "status"=>"failed"}}}
SAMPLE_TEST_EXECUTIONS_MESSAGE_RESPONSE = {
  "status"=>0,
  "report"=>SAMPLE_REPORT_URL,
  "session_status"=>"passed",
  "session_done"=>true,
  "messages"=>[SAMPLE_MESSAGE_ENTRY, SAMPLE_MESSAGE_ENTRY],
  "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/pig_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/dog_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}}
SAMPLE_TEST_EXECUTIONS_WARNING_RESPONSE = {
  "status"=>0,
  "report"=>SAMPLE_REPORT_URL,
  "session_status"=>"passed",
  "session_done"=>true,
  "messages"=>[SAMPLE_WARNING_MESSAGE_ENTRY, SAMPLE_WARNING_MESSAGE_ENTRY],
  "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/pig_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/dog_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}}
SAMPLE_TEST_EXECUTIONS_NOMSG_RESPONSE = {
  "status"=>0,
  "report"=>SAMPLE_REPORT_URL,
  "session_status"=>"passed",
  "session_done"=>true,
  "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/pig_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/dog_spec.rb"=>{"finished" => true, "status"=>"passed"},
            "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}}
SAMPLE_TEST_EXECUTIONS_FINISHED_RESPONSE = {
  "status"=>0,
  "report"=>SAMPLE_REPORT_URL,
  "session_status"=>"error",
  "session_done"=>true,
  "tests"=>{"spec/mouse_spec.rb"=>{"finished" => true, "status"=>"pending"},
            "spec/pig_spec.rb"=>{"finished" => true, "status"=>"error"},
            "spec/dog_spec.rb"=>{"finished" => true, "status"=>"failed"},
            "spec/cat_spec.rb"=>{"finished" => true, "status"=>"passed"}}}

