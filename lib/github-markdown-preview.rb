
module GithubMarkdownPreview
  class FileNotFoundError < StandardError; end

  require 'github-markdown-preview/version'
  require 'github-markdown-preview/resources'
  require 'github-markdown-preview/html_preview'
end