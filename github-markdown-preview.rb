#!/usr/bin/ruby

require 'rubygems'
require 'listen'
require 'html/pipeline'

file_name = ARGV.at(0)

# get paths to our local copies of the Github CSS
# NOTE: these files will probably get stale and should be refreshed from github periodically
#     (we can't point to a static github path because they append a version number within their filename)
script_dir = File.expand_path(File.dirname(__FILE__))
github_css_1 = "file://" + script_dir + "/css/github.css"
github_css_2 = "file://" + script_dir + "/css/github2.css"

def update_preview(file_name, css_1, css_2)

  context = {
      :asset_root => "https://a248.e.akamai.net/assets.github.com/images/icons/",
      :gfm => true
  }

  pipeline = HTML::Pipeline.new [
      HTML::Pipeline::MarkdownFilter,
      HTML::Pipeline::SanitizationFilter,
      HTML::Pipeline::ImageMaxWidthFilter,
      HTML::Pipeline::HttpsFilter,
      HTML::Pipeline::MentionFilter,
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

  out_file = File.open('/tmp/markdownPreview.html', 'w')
  out_file.write(output_file_content)
  out_file.close
end

# generate the preview on load...
update_preview(file_name, github_css_1, github_css_2)

# ...then listen for changes and refresh it needed
Listen.to(Dir.pwd, :relative_paths => true) do |modified, _, _|
  if modified.inspect.include?(file_name)
    update_preview(file_name, github_css_1, github_css_2)
  end
end