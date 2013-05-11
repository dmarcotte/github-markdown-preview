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
  s.summary     = %q{Local previews for Github Flavored Markdown files}
  s.description = %q{Use your favorite editor plus the usual edit/refresh cycle to quickly write and polish your Github markdown files.}
  s.license     = 'MIT'

  s.add_dependency 'listen', '~> 1.0.3'
  s.add_dependency 'github-linguist', '~> 2.6.7'
  s.add_dependency 'html-pipeline', '~> 0.0.12'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = %w(lib)
end
