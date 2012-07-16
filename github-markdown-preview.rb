require 'rubygems'
require 'listen'
require 'github/markdown'

file_name = ARGV.at(0)

# paths to the github css files; needed to get an accurate preview of the formatting on github.
# NOTE: these links break when github updates their css.  This is good... that's how we know it's time to
# grab a fresh link to keep out previews accurate
github_css_1 = "https://a248.e.akamai.net/assets.github.com/stylesheets/bundles/github-c1b259ab57c9cca1c697baded9ecd8278b4026f9.css"
github_css_2 = "https://a248.e.akamai.net/assets.github.com/stylesheets/bundles/github2-9a6987061a89bac7e001fbfac3a4a9e99aeb9436.css"


def update_preview(file_name, css_1, css_2)
  out_file = File.open('/tmp/markdownPreview.html', 'w')
  out_file.write('<body class="markdown-body" style="padding:20px">')
  out_file.write('<div id="slider">')
  out_file.write('<div class="frames">')
  out_file.write('<div class="frame frame-center">')
  out_file.write('<link rel=stylesheet type=text/css href="' + css_1 + '">')
  out_file.write('<link rel=stylesheet type=text/css href="' + css_2 + '">')
  out_file.write(GitHub::Markdown.render(File.new(file_name).read))
  out_file.write('</div>')
  out_file.write('</div>')
  out_file.write('</div>')
  out_file.write('</body>')
  out_file.close
end

# generate the preview on load...
update_preview(file_name, github_css_1, github_css_2)

# then listen for changes and refresh it when needed
Listen.to(Dir.pwd, :relative_paths => true) do |modified, added, removed|
  if modified.inspect.include?(file_name)
    update_preview(file_name, github_css_1, github_css_2)
  end
end