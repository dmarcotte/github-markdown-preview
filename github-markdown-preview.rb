require 'rubygems'
require 'listen'
require 'github/markdown'

file_name = ARGV.at(0)

# get paths to our local copies of the Github CSS
# NOTE: these files will probably get stale and should be refreshed from github periodically
#     (we can't point to a static github path because they append a version number within their filename)
script_dir = File.expand_path(File.dirname(__FILE__))
github_css_1 = "file://" + script_dir + "/css/github.css"
github_css_2 = "file://" + script_dir + "/css/github2.css"


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