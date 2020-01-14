# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'github-markdown-preview/version'

Gem::Specification.new do |s|
  s.name        = 'github-markdown-preview'
  s.version     = GithubMarkdownPreview::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Daniel Marcotte']
  s.email       = 'dmarcotte@gmail.com'
  s.homepage    = 'https://github.com/dmarcotte/github-markdown-preview'
  s.summary     = %q{Use your favorite editor plus the usual edit/refresh cycle to quickly write and polish your Github markdown}
  s.description = %q{Local previews for Github markdown}
  s.license     = 'MIT'

  s.add_dependency 'listen', '3.2.1'
  s.add_dependency 'html-pipeline', '2.12.3'
  s.add_dependency 'commonmarker', '0.20.2'
  s.add_dependency 'sanitize', '5.1.0'
  s.add_dependency 'escape_utils', '1.2.1'
  s.add_dependency 'gemoji', '3.0.1'
  s.add_dependency 'rouge', '3.14.0'

  s.add_development_dependency 'minitest', '~> 5.14.0'
  s.add_development_dependency 'rake', '~> 13.0.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
