module GithubMarkdownPreview
  class Resources
    ##
    # Transforms a resource_path in data/ into an absolute path
    def self.expand_path(resource_path)
      File.join(File.dirname(File.expand_path(__FILE__)), '..', '..', 'data', resource_path)
    end
  end
end