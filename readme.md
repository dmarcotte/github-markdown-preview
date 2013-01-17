# Local Github Markdown Preview

Use your favorite editor plus the usual edit/refresh cycle to quickly write and polish your Github markdown files.

This simple script marries [html-pipeline](https://github.com/jch/html-pipeline) with the [Listen file watcher](https://github.com/guard/listen) to provide a high-fidelity preview of Github Flavored Markdown in your local browser which automatically updates on edit.

![sample screenshot](https://raw.github.com/dmarcotte/github-markdown-preview/5550878814c72bfcb02a033b4ca4ec9c8feb3216/screenshot.png "Local Github Markdown Preview output")

## Installing
* Grab the dependencies:

    ```bash
    gem install html-pipeline
    gem install listen
    ```
* Clone this repository, add the directory to your `PATH`
* `git pull` for updates

## Usage
```bash
# This will write the html preview to /tmp/markdownPreview.html.  Open in your favorite browser and enjoy!
github-markdown-preview.rb <path/to/github-flavored/.md/file>
```
* You can preview as many files as you like simultaneously.  The contents of `/tmp/markdownPreview.html` will be determined by the last edited file
* I set up a "External Tool" in my IDE which launches `github-markdown-preview` for the active file.  Your favorite IDE/Text-editor should have a similar mechanism

## Contributing

If the script isn't working as promised, please [file an issue](https://github.com/dmarcotte/github-markdown-preview/issues)!

As for new features, in its current state, this script is meeting my needs so I probably won't be beefing it up much.  I acknowledge that it's pretty low-fi though, so if you've got desires to make it more slick, send a [pull](https://github.com/dmarcotte/github-markdown-preview/pulls)!