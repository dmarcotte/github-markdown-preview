#!/usr/bin/ruby

require 'rubygems'
require 'listen'
require 'html/pipeline'

unless ARGV.count == 1
  puts "Please supply the name of a markdown file as the first agument."
  exit 1
end

watched_file = File.expand_path(ARGV.at(0))
watched_file_dir = File.dirname(watched_file)
preview_file = watched_file + '.html'

# delete preview html on exit
trap("EXIT") {
  File.delete(preview_file)
}

# get paths to our local copies of the Github CSS
# NOTE: these files will probably get stale and should be refreshed from github periodically
#     (we can't point to a static github path because they append a version number within their filename)
script_location = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
script_dir = File.expand_path(File.dirname(script_location))
github_css_1 = "file://" + script_dir + "/css/github.css"
github_css_2 = "file://" + script_dir + "/css/github2.css"

def update_preview(file_name, preview_file, css_1, css_2)

  context = {
      :asset_root => "https://a248.e.akamai.net/assets.github.com/images/icons/",
      :gfm => true
  }

  pipeline = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::SanitizationFilter,
      HTML::Pipeline::ImageMaxWidthFilter,
      HTML::Pipeline::HttpsFilter,
      HTML::Pipeline::EmojiFilter,
      HTML::Pipeline::SyntaxHighlightFilter
  ]

  markdown_render = pipeline.call(File.new(file_name).read, context, {})[:output].to_s

  output_file_content =<<CONTENT

<body class="markdown-body" style="padding:20px; overflow-y: scroll">
  <link rel=stylesheet type=text/css href="#{css_1}">
  <link rel=stylesheet type=text/css href="#{css_2}">
  <div id="slider">
    <div class="frames">
      <div class="frame frame-center">
        #{markdown_render}
      </div>
    </div>
  </div>
</body>

CONTENT

  out_file = File.open(preview_file, 'w')
  out_file.write(output_file_content)
  out_file.close
end

# generate the preview on load...
update_preview(watched_file, preview_file, github_css_1, github_css_2)
if $stdout.isatty
  puts "Preview viewable at file://#{preview_file}"
end

callback = Proc.new do |modified, added, removed|
  if modified.inspect.include?(watched_file)
    update_preview(watched_file, preview_file, github_css_1, github_css_2)
  end
end

# ...then wait and listen for changes and refresh it needed
listener = Listen.to(watched_file_dir)
listener.change(&callback)
listener.latency(0.1)
listener.ignore(/.*\/.*/) # ignore all subdirectories
listener.start
