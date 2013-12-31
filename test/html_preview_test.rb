require 'github-markdown-preview'
require 'minitest/autorun'
require 'tmpdir'

begin
  require 'linguist'
  LINGUIST_LOADED = true
rescue LoadError => _
  LINGUIST_LOADED = false
end

class TestHtmlPreview < Minitest::Test

  def setup
    @ghp = GithubMarkdownPreview::HtmlPreview
    @source_file_path = File.join(Dir.tmpdir, 'test.md')
  end

  def write(file_name, text)
    File.open(file_name, 'w') do |f|
      f.puts(text)
    end
  end

  def read(file_name)
    assert File.exist?(file_name), "Cannot read file: #{file_name}"
    File.open(file_name).read
  end

  ##
  # Helper method based on Fowler's advice in http://martinfowler.com/articles/nonDeterminism.html#AsynchronousBehavior
  #
  # Requires you pass a block which returns true when your asynchronous process has finished
  def wait_for_async_operation
    start_time = Time.now
    wait_limit = 30
    polling_interval = 0.2

    until yield
      if Time.now - start_time > wait_limit
        flunk 'Async operation should not time out.'
      end
      sleep (polling_interval)
    end
  end

  def test_create_preview_on_init
    write(@source_file_path, '## foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_match /.*<h2>foo<\/h2>.*/,
                 read(markdown_preview.preview_file),
                 'Preview should be correct on initialization'
  end

  def test_word_immediately_after_hash
    write(@source_file_path, '#foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_match /.*<h1>foo<\/h1>.*/,
                 read(markdown_preview.preview_file),
                 'Preview should render #foo as a header'
  end

  def test_comment_mode_word_immediately_after_hash
    write(@source_file_path, '#foo')
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    assert_match /.*#foo*/,
                 read(markdown_preview.preview_file),
                 'Preview should render #foo directly'
  end

  def test_newlines_ignored
    write(@source_file_path, "foo\nbar")
    markdown_preview = @ghp.new( @source_file_path )
    assert_match /.*foo\nbar*/,
                 read(markdown_preview.preview_file),
                 'Should not contain <br> for newline'
  end

  def test_comment_mode_newlines_respected
    write(@source_file_path, "foo\nbar")
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    assert_match markdown_preview.wrap_preview("<p>foo<br>\nbar</p>"),
                 read(markdown_preview.preview_file),
                 'Should insert <br> for newline in comment mode'
  end

  def test_at_mentions_not_linked
    write(@source_file_path, "@username")
    markdown_preview = @ghp.new( @source_file_path )
    assert_match markdown_preview.wrap_preview("<p>@username</p>"),
                 read(markdown_preview.preview_file),
                 '@mentions should not be linked'
  end

  def test_comment_mode_at_mentions_linked
    write(@source_file_path, "@username")
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    assert_match markdown_preview.wrap_preview('<p><a href="https://github.com/username" class="user-mention">@username</a></p>'),
                 read(markdown_preview.preview_file),
                 '@mentions should create links'
  end

  def test_wrapper_markup_included
    write(@source_file_path, '## foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview("<h2>foo<\/h2>"),
                 read(markdown_preview.preview_file),
                 'Wrapper markup should be in preview file'
  end

  if LINGUIST_LOADED
    def test_uses_syntax_highlighting
      write(@source_file_path, "```ruby\nnil\n```")
      markdown_preview = @ghp.new( @source_file_path )

      assert_equal markdown_preview.wrap_preview("<div class=\"highlight highlight-ruby\"><pre><span class=\"kp\">nil</span>\n</pre></div>"),
                   read(markdown_preview.preview_file),
                   'Decorated code should be in preview file'
    end
  else
    def test_no_syntax_highlighting
      write(@source_file_path, "```ruby\nnil\n```")
      markdown_preview = @ghp.new( @source_file_path )
      assert_equal markdown_preview.wrap_preview("<pre lang=\"ruby\"><code>nil\n</code></pre>"),
                   read(markdown_preview.preview_file),
                   'Undecorated code should be in preview file'
    end
  end

  def test_update_preview
    write(@source_file_path, '## foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_match /.*<h2>foo<\/h2>.*/, read(markdown_preview.preview_file),
                 'Preview should be initially rendered correctly'

    write(@source_file_path, '## foo bar')
    markdown_preview.update
    assert_match /.*<h2>foo bar<\/h2>.*/,
                 read(markdown_preview.preview_file),
                 'Preview should be updated correctly'
  end

  def test_preview_beside_src_file
    write(@source_file_path, '## foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal File.dirname(Pathname.new(@source_file_path).realpath),
                 File.dirname(Pathname.new(markdown_preview.preview_file).realpath),
                 'Preview file should be in same dir as source file'
  end

  def test_preview_delete
    write(@source_file_path, '## foo')
    markdown_preview = @ghp.new( @source_file_path )
    markdown_preview.delete
    assert !File.exist?(markdown_preview.preview_file), 'Preview file should been deleted'
  end

  def test_preview_delete_on_exit
    at_exit { assert !File.exist?(@source_file_path + '.html'), 'Preview file should be deleted on exit' }
    write(@source_file_path, '## foo')
    @ghp.new( @source_file_path, { :delete_on_exit => true } )
  end

  def test_update_callbacks
    write(@source_file_path, '## foo')
    markdown_preview = @ghp.new( @source_file_path )
    first_update_callback_called = false
    second_update_callback_called = false
    markdown_preview.on_update { first_update_callback_called = true }
    markdown_preview.on_update { second_update_callback_called = true }
    markdown_preview.update
    assert first_update_callback_called, 'First update callback should be called'
    assert second_update_callback_called, 'Second update callback should be called'
  end

  def test_watch_source_file
    write(@source_file_path, '## foo')
    markdown_preview = @ghp.new( @source_file_path )
    updated_by_watch = false
    markdown_preview.on_update { updated_by_watch = true }
    markdown_preview.watch

    wait_for_async_operation {
      write(@source_file_path, '## foo bar')
      updated_by_watch
    }

    markdown_preview.end_watch

    assert_match /.*<h2>foo bar<\/h2>.*/,
                 read(markdown_preview.preview_file)
                 'Preview file should be updated correctly by file watcher'
  end

  def test_file_not_found
    assert_raises GithubMarkdownPreview::FileNotFoundError do
      @ghp.new('this_file_does_not_exist')
    end
  end

  def test_file_deleted_behind_us
    assert_raises GithubMarkdownPreview::FileNotFoundError do
      write(@source_file_path, '## foo')
      markdown_preview = @ghp.new( @source_file_path )
      File.delete(@source_file_path)
      markdown_preview.update
    end
  end

end
