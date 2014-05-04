require_relative 'test_helper'
require 'minitest/autorun'

class TestBin < Minitest::Test
  def setup
    @ghp_scipt = File.join(File.dirname(__FILE__), '..', 'bin', 'github-markdown-preview')
  end

  def test_no_params
    IO.popen("bundle exec #{@ghp_scipt}") do |io|
      assert_match /Usage.*/, io.read, 'No parameter call should output usage'
    end
  end

  def test_version_ouput
    IO.popen("bundle exec #{@ghp_scipt} -v") do |io|
      assert_match GithubMarkdownPreview::VERSION, io.read, '-v call should output version'
    end
  end

  def test_file_not_found
    IO.popen("bundle exec #{@ghp_scipt} this_file_does_not_exist 2>&1") do |io|
      assert_match /.*No such file/, io.read, 'Bad file name should get a helpful error'
    end
  end
end