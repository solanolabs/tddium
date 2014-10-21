# Copyright (c) 2014 Solano Labs All Rights Reserved

require 'spec_helper'
require 'tddium/scm/scm'
require 'tddium/scm/git'
require 'tddium/scm/hg'
require 'tddium/constant'

describe Tddium::SCM do
  include TddiumConstant
  
  describe '.configure' do
    context 'for git repo' do
      let(:tddium_git) { double(Tddium::Git).as_null_object }

      context 'when git is installed' do
        it "doesn't abort" do
          Tddium::Git.any_instance.should_receive(:repo?).and_return true
          Tddium::Git.stub(:`).with('git --version').and_return 'git version 1.9.3 (Apple Git-50)'
          Tddium::Git.should_receive(:new).and_call_original
          Tddium::Hg.should_not_receive(:new)

          expect{ Tddium::SCM.configure }.not_to raise_error
        end

        it 'returns correct SCM instance' do
          Tddium::Git.should_receive(:new).and_return tddium_git
          tddium_git.should_receive(:repo?).and_return true
          tddium_git.class.stub(:version_ok)
          Tddium::Git.stub(:`).with('git --version').and_return 'git version 1.9.3 (Apple Git-50)'
          Tddium::Hg.should_not_receive(:new)

          expect(Tddium::SCM.configure).to eq(tddium_git)
        end
      end

      context 'when git is not installed' do
        it 'aborts with message' do
          Tddium::Git.should_receive(:new).and_call_original
          Tddium::Git.any_instance.should_receive(:repo?).and_return true
          Tddium::Git.stub(:`).with('git --version').and_raise Exception
          Tddium::Hg.should_not_receive(:new)

          expect{
            Tddium::SCM.configure
          }.to raise_error(SystemExit, self.class::Text::Error::SCM_NOT_FOUND)
        end
      end
    end

    context 'for mercurial repo' do
      context 'when mercurial is installed' do
        let(:tddium_hg) { double(Tddium::Hg).as_null_object }

        it "doesn't abort" do
          Tddium::Git.any_instance.should_receive(:repo?).and_return false
          Tddium::Git.any_instance.should_not_receive(:version_ok)

          Tddium::Hg.should_receive(:new).and_call_original
          Tddium::Hg.any_instance.should_receive(:repo?).and_return true
          Tddium::Hg.stub(:`).with('hg -q --version').and_return 'Mercurial Distributed SCM (version 3.1.1)'

          expect{
            Tddium::SCM.configure
          }.not_to raise_error
        end

        it 'returns correct SCM instance' do
          Tddium::Git.any_instance.should_receive(:repo?).and_return false
          Tddium::Git.any_instance.should_not_receive(:version_ok)

          Tddium::Hg.stub(:`).with('hg -q --version').and_return 'Mercurial Distributed SCM (version 3.1.1)'
          Tddium::Hg.stub(:new).and_return tddium_hg
          tddium_hg.should_receive(:repo?).and_return true
          tddium_hg.class.stub(:version_ok)
          
          expect(Tddium::SCM.configure).to eq(tddium_hg)
        end
      end

      context 'when mercurial is not installed' do
        it 'abort with message' do
          Tddium::Git.any_instance.should_receive(:repo?).and_return false
          Tddium::Git.any_instance.should_not_receive(:version_ok)

          Tddium::Hg.should_receive(:new).and_call_original
          Tddium::Hg.any_instance.should_receive(:repo?).and_return true
          Tddium::Hg.stub(:`).with('hg -q --version').and_raise(Exception)

          expect{
            Tddium::SCM.configure
          }.to raise_error(SystemExit, self.class::Text::Error::SCM_NOT_FOUND)
        end
      end
    end

    context 'for non git and non mercurial repo' do
      let(:tddium_git) { double(Tddium::Git).as_null_object }
      let(:tddium_hg) {  }

      it 'returns git scm' do
        Tddium::Git.stub(:new).and_return tddium_git
        tddium_git.should_receive(:repo?).and_return false
        tddium_git.class.stub(:version_ok)
        Tddium::Hg.any_instance.should_receive(:repo?).and_return false

        expect(Tddium::SCM.configure).to eq(tddium_git)
      end
    end
  end
end
