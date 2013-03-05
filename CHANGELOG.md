# Changelog

## v1.3
* fix scroll issue which was causing page position to be lost on refresh
* update github css

## v1.2
* output help text on incorrect arguments
* output location of preview file for easy viewing
* update install instructions to clarify some dependencies

## v1.1
* write the `.html` preview beside the source `.md` file to support [relative links](https://github.com/blog/1395-relative-links-in-markup-files)
* remove the MentionFilter (which makes `@username` links) since these are not linked on Github

## v1.0
* initial release
* writes a `.html` high-fidelity preview of a given github flavored `.md` file to `/tmp/markdownPreview.html`