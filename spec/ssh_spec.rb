# Copyright (c) 2014 Solano Labs All Rights Reserved

require 'tddium/constant'
require 'spec_helper'
require 'tddium/cli'
require 'tddium/ssh'

describe Tddium::Ssh do
  include_context "tddium_api_stubs"
  include TddiumConstant

  describe '.validate_keys' do
    let(:key) do
      { 'name' => 'some_key',
        'pub' => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZiP/MC0sT7pvXsh6ElZ9zlJwYqc2fOA/YFzMJFW89Ii3JZtaB0eOpT+fA2+BTxN5vlbDpgFi1A53rZ/iscdZWhIfMzRX/ehAQjs2jNgcj5k5kxjq3hRs3ULWAUqC+Ep1xh6I8Ev7e/wHuZSvXVR8ILWXhwzFTHd0VHQ4fnu7gyXD6Ka+DUSTJ7ydtbH7BS7voZeGdiJKPJkqe/cD7lzT3iznaXJGr1GwX4CQFgdOoJIwsrFx0CkiPDZ8eIxRTpfn80n+s3tM3HEERAnkJGVkymYVipfqmzBoL9zcwNZYg/S7GyBBwVRL+pZ2bpulydQ7FxXoU1cpPvHyX55c1Ufq7 wkj@tddium' }
    end
    let(:another_key) do
      { name: 'title',
        pub: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCZiP/MC0sT7pvXsh6ElZ9zlJwYqc2fOA/YFzMJFW89Ii3JZtaB0eOpT+fA2+BTxN5vlbDpgFi1A53rZ/iscdZWhIfMzRX/ehAQjs2jNgcj5k5kxjq3hRs3ULWAUqC+Ep1xh6I8Ev7e/wHuZSvXVR8ILWXhwzFTHd0VHQ4fnu7gyXD6Ka+DUSTJ7ydtbH7BS7voZeGdiJKPJkqe/cD7lzT3iznaXJGr1GwX4CQFgdOoJIwsrFx0CkiPDZ8eIxRTpfn80n+s3tM3HEERAnkJGVkymYVipfqmzBoL9zcwNZYg/S7GyBBwVRL+pZ2bpulydQ7FxXoU1cpPvHyX55c1Ufq7 wkj@tddium' }
    end

    it "aborts adding duplicate key's name" do
      tddium_api.stub(:get_keys).and_return([key])
      Tddium::Ssh.stub(:load_ssh_key).and_return(key)

      expect{
        subject.class.validate_keys(key['name'], 'some/path', tddium_api, false)
      }.to raise_error(SystemExit, self.class::Text::Error::ADD_KEYS_DUPLICATE % key['name'])
    end

    it "aborts adding duplicate key's content" do
      tddium_api.stub(:get_keys).and_return([key])
      Tddium::Ssh.stub(:load_ssh_key).and_return(another_key)

      expect{
        subject.class.validate_keys(another_key['name'], 'some/path', tddium_api, false)
      }.to raise_error(SystemExit, self.class::Text::Error::ADD_KEY_CONTENT_DUPLICATE % key['name'])
    end
  end
end
