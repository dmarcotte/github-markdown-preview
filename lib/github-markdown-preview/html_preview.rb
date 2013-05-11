require 'listen'
require 'html/pipeline'

module GithubMarkdownPreview

  ##
  # Creates an high-fidelity html preview of the given markdown file
  #
  # For a given file /path/to/file.md, generates /path/to/file.md.html
  class HtmlPreview

    VERSION = '1.5'

    attr_reader :source_file, :preview_file
    attr_accessor :delete_on_exit

    def initialize(source_file)
      @source_file = File.expand_path(source_file)

      unless File.exist?(@source_file)
        raise FileNotFoundError.new("Cannot find source file: #{source_file}")
      end

      @preview_file = @source_file + '.html'
      @update_callbacks = []

      @pipeline_context = {
          :asset_root => "https://a248.e.akamai.net/assets.github.com/images/icons/",
          :gfm => true
      }

      @preview_pipeline = HTML::Pipeline.new [
                                                 HTML::Pipeline::MarkdownFilter,
                                                 HTML::Pipeline::SanitizationFilter,
                                                 HTML::Pipeline::ImageMaxWidthFilter,
                                                 HTML::Pipeline::HttpsFilter,
                                                 HTML::Pipeline::EmojiFilter,
                                                 HTML::Pipeline::SyntaxHighlightFilter
                                             ]

      # generate initial preview
      update

      at_exit do
        if :delete_on_exit
          delete
        end
      end

      # set up a listener which ca be asked to watch for updates
      source_file_dir = File.dirname(@source_file)
      @listener = Listen.to(source_file_dir)

      # only look at files who's basename matches the file we care about
      # we could probably be more aggressive and make sure it's the *exact* file,
      # but this is simpler, should be cross platform and at worst means a few no-op updates
      @listener.filter(%r{.*#{File.basename(@source_file)}$})

      # teach our listener how to update on change
      @listener.change do
        update
      end
    end

    ##
    # Update the preview file
    def update
      unless File.exists?(@source_file)
        raise FileNotFoundError.new("Source file deleted")
      end

      markdown_render = @preview_pipeline.call(File.open(@source_file).read, @pipeline_context, {})[:output].to_s
      preview_html = wrap_preview(markdown_render)

      File.open(@preview_file, 'w') do |f|
        f.write(preview_html)
      end

      @update_callbacks.each { |callback| callback.call() }
    end

    ##
    # Register a callback to be fired when the preview is updated
    #
    # Multiple calls to this will register multiple callbacks
    def on_update(&update_callback)
      @update_callbacks << update_callback
    end

    ##
    # Watch source file for changes, updating preview on change
    #
    # Non-blocking version of #watch!
    def watch
      @listener.start
    end

    ##
    # Watch source file for changes, updating preview on change
    #
    # Blocking version of #watch
    def watch!
      @listener.start!
    end

    ##
    # Stop watching source file (only applies to previews using the non-blocking #watch)
    def end_watch
      @listener.stop
    end

    ##
    # Delete the preview file from disk
    def delete
      if File.exist?(@preview_file)
        File.delete(@preview_file)
      end
    end

    ##
    # Wrap the given html in a full page of github-ish html for rendering and styling
    def wrap_preview(preview_html)
      output_file_content =<<CONTENT
    <head>
      <link rel=stylesheet type=text/css href="#{Resources.expand_path(File.join('css','github.css'))}">
      <link rel=stylesheet type=text/css href="#{Resources.expand_path(File.join('css','github2.css'))}">
      <style type="text/css">
        html, .markdown-body {
          overflow: inherit;
        }
        .markdown-body h1 {
          margin-top: 0;
        }
      </style>
    </head>
    <body class="markdown-body" style="padding:20px;">
      <div id="slider">
        <div class="frames">
          <div class="frame frame-center">
            #{preview_html}
          </div>
        </div>
      </div>
    </body>
CONTENT
      output_file_content
    end

  end

end