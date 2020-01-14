require 'listen'
require 'commonmarker'
require 'html/pipeline'

module GithubMarkdownPreview

  ##
  # Creates an high-fidelity html preview of the given markdown file
  #
  # For a given file /path/to/file.md, generates /path/to/file.md.html
  class HtmlPreview
    attr_reader :source_file, :preview_file

    def initialize(source_file, options = {})
      unless File.exist?(source_file)
        raise FileNotFoundError.new("Cannot find source file: #{source_file}")
      end

      @source_file = Pathname.new(source_file).realpath.to_s

      options = {
          :delete_on_exit => false,
          :comment_mode => false,
          :preview_file => @source_file + '.html'
      }.merge(options)

      @preview_file = options[:preview_file]
      @preview_width = options[:comment_mode] ? 712 : 722

      @update_callbacks = []

      @pipeline_context = pipeline_context(options)

      @preview_pipeline = HTML::Pipeline.new pipeline_filters(options)

      # generate initial preview
      update

      at_exit do
        if options[:delete_on_exit]
          delete
        end
      end
    end

    ##
    # Compute the context to pass to html-pipeline based on the given options
    def pipeline_context(options)
      {
          :asset_root => "https://a248.e.akamai.net/assets.github.com/images/icons/",
          :base_url => "https://github.com/",
          :gfm => options[:comment_mode],
          :disabled_tasks => !options[:comment_mode]
      }
    end

    ##
    # Compute the filters to use in the html-pipeline based on the given options
    def pipeline_filters(options)
      filters = [
          HTML::Pipeline::MarkdownFilter,
          HTML::Pipeline::SanitizationFilter,
          HTML::Pipeline::ImageMaxWidthFilter,
          HTML::Pipeline::HttpsFilter,
          HTML::Pipeline::EmojiFilter,
          GithubMarkdownPreview::Pipeline::TaskListFilter,
          HTML::Pipeline::SyntaxHighlightFilter
      ]

      if options[:comment_mode]
        filters << HTML::Pipeline::MentionFilter
      else
        filters << HTML::Pipeline::TableOfContentsFilter
      end

      filters
    end

    ##
    # Update the preview file
    def update
      unless File.exist?(@source_file)
        raise FileNotFoundError.new("Source file deleted")
      end

      markdown_render = @preview_pipeline.call(IO.read(@source_file), @pipeline_context, {})[:output].to_s
      preview_html = wrap_preview(markdown_render)

      File.open(@preview_file, 'w') do |f|
        f.write(preview_html)
      end

      @update_callbacks.each { |callback| callback.call }
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
      start_watch
    end

    ##
    # Watch source file for changes, updating preview on change
    #
    # Blocking version of #watch
    def watch!
      start_watch true
    end

    def start_watch(blocking = false)
      unless @listener
        # set up a listener which ca be asked to watch for updates
        source_file_dir = File.dirname(@source_file)

        @listener = Listen.to(source_file_dir) { update }

        # only look at files who's basename matches the file we care about
        # we could probably be more aggressive and make sure it's the *exact* file,
        # but this is simpler, should be cross platform and at worst means a few no-op updates
        @listener.only(%r{.*#{File.basename(@source_file)}$})
      end
      @listener.start
      sleep if blocking
    end
    private :start_watch

    ##
    # Stop watching source file (only applies to previews using the non-blocking #watch)
    def end_watch
      if @listener
        @listener.stop
      end
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
      <meta charset="utf-8">
      <style type="text/css">
        #{IO.read(Resources.expand_path(File.join('css','github.css')))}
        #{IO.read(Resources.expand_path(File.join('css','github2.css')))}

        html, .markdown-body {
          overflow: inherit;
        }
        .markdown-body h1 {
          margin-top: 0;
        }
        .readme-content {
          width: #{@preview_width}px;
        }

        /* hack in an anchor icon */
        .markdown-body h1:hover a.anchor, .markdown-body h2:hover a.anchor, .markdown-body h3:hover a.anchor, .markdown-body h4:hover a.anchor, .markdown-body h5:hover a.anchor, .markdown-body h6:hover a.anchor {
          padding: 8px 13px;
          margin: 0px 0px 12px -27px;
          background: url('data:image/png;base64,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')
                      no-repeat
                      left center;
        }
        .markdown-body h1:hover a.anchor .octicon-link, .markdown-body h2:hover a.anchor .octicon-link, .markdown-body h3:hover a.anchor .octicon-link, .markdown-body h4:hover a.anchor .octicon-link, .markdown-body h5:hover a.anchor .octicon-link, .markdown-body h6:hover a.anchor .octicon-link {
          display: none;
        }
      </style>
    </head>
    <body class="markdown-body" style="padding:10px 40px;">
      <div class="readme-content">
        #{preview_html}
      </div>
    </body>
CONTENT
      output_file_content
    end

  end

end
