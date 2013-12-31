# Local Github Markdown Preview [![Build Status](https://secure.travis-ci.org/dmarcotte/github-markdown-preview.png)](http://travis-ci.org/dmarcotte/github-markdown-preview)

Use your favorite editor plus the usual edit/refresh cycle to quickly write and polish your Github markdown files.

This program marries [html-pipeline](https://github.com/jch/html-pipeline) with the [Listen file watcher](https://github.com/guard/listen) to provide a high-fidelity preview of Github Flavored Markdown in your local browser which automatically updates on edit.

![sample screenshot](sample.png "Local Github Markdown Preview output")

## Installing
```
gem install github-markdown-preview
```

### Enabling syntax highlighting for code blocks
To enable syntax highlighting for code blocks, you will need to install [`github-linguist`](https://github.com/github/linguist):
```
gem install github-linguist
```

Note that this install will fail unless your system meets the requirements needed to build it native extensions:
* You will to either `brew install icu4c` or `apt-get install libicu-dev`
* On Mac, you will need to have XCode installed (seems like a full install is required, not just the Command Line Tools)

## Usage
### Command line
```bash
# This will write the html preview along side your markdown file (<path/to/markdown/file.md.html>)
# Open in your favorite browser and enjoy!
github-markdown-preview <path/to/markdown/file.md>
```
* The `.html` preview is written beside your `.md` file so that you can validate [relative links](https://github.com/blog/1395-relative-links-in-markup-files) locally
* The `.html` preview is deleted when the script exits

### Code
```ruby
require 'github-markdown-preview'

# create a preview, which writes the source_file.md.html file to disk
preview = GithubMarkdownPreview::HtmlPreview.new('source_file.md')

# access the preview information
preview.source_file # returns 'source_file.md'
preview.preview_file # returns 'source_file.md.html'

# explicitly update the preview file from the source
preview.update

# watch the source file and update the preview on change
preview.watch # non-blocking watch
preview.watch! # blocking watch

# add a callback to be fired on update; add multiple listeners by calling again
preview.update { puts 'Preview updated!' }

# stop watching the file (only applies to non-blocking watch method)
preview.end_watch

# delete the preview file from disk
preview.delete

# alternatively, tell the preview to delete itself when your program exits
preview.delete_on_exit = true
```

## Developing
```bash
$ bundle install
$ rake test
```

Alternatively, to test with optional dependencies
```bash
$ BUNDLE_GEMFILE=Gemfile.optional bundle install
$ BUNDLE_GEMFILE=Gemfile.optional rake test
```

To run your development copy of the main script without installing it
```bash
$ bundle exec bin/github-markdown-preview
```
To install the your development copy to your system
```bash
$ rake install
```

## Contributing

[Contributions](contributing.md) welcome!
