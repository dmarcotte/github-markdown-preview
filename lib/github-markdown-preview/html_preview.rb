require 'listen'
require 'html/pipeline'

module GithubMarkdownPreview

  ##
  # Creates an high-fidelity html preview of the given markdown file
  #
  # For a given file /path/to/file.md, generates /path/to/file.md.html
  class HtmlPreview
    attr_reader :source_file, :preview_file

    begin
      require 'linguist'
      SYNTAX_HIGHLIGHTS = true
    rescue LoadError => _
      SYNTAX_HIGHLIGHTS = false
    end

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

      # set up a listener which ca be asked to watch for updates
      source_file_dir = File.dirname(@source_file)

      @listener = Listen.to(source_file_dir) { update }

      # only look at files who's basename matches the file we care about
      # we could probably be more aggressive and make sure it's the *exact* file,
      # but this is simpler, should be cross platform and at worst means a few no-op updates
      @listener.only(%r{.*#{File.basename(@source_file)}$})
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
          GithubMarkdownPreview::Pipeline::TaskListFilter
      ]

      if HtmlPreview::SYNTAX_HIGHLIGHTS
        filters << HTML::Pipeline::SyntaxHighlightFilter
      end

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
      unless File.exists?(@source_file)
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
      @listener.start
      sleep if blocking
    end
    private :start_watch

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
      </style>
    </head>
    <body class="markdown-body" style="padding:20px;">
      <div class="readme-content">
        #{preview_html}
      </div>
    </body>
CONTENT
      output_file_content
    end

  end

end
