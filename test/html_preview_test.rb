require 'github-markdown-preview'
require 'minitest/autorun'
require 'tmpdir'

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
    write(@source_file_path, 'foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview('<p>foo</p>'),
                 read(markdown_preview.preview_file),
                 'Preview should be correct on initialization'
  end

  def test_word_immediately_after_hash
    write(@source_file_path, 'foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview('<p>foo</p>'),
                 read(markdown_preview.preview_file),
                 'Preview should render #foo as a header'
  end

  def test_comment_mode_word_immediately_after_hash
    write(@source_file_path, '#foo')
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    assert_equal markdown_preview.wrap_preview('<p>#foo</p>'),
                 read(markdown_preview.preview_file),
                 'Preview should render #foo directly'
  end

  def test_default_mode_anchors
    write(@source_file_path, "# foo\n## bar")
    markdown_preview = @ghp.new( @source_file_path )
    html = <<HTML
<h1>
<a id=\"foo\" class=\"anchor\" href=\"#foo\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>foo</h1>
<h2>
<a id=\"bar\" class=\"anchor\" href=\"#bar\" aria-hidden=\"true\"><span aria-hidden=\"true\" class=\"octicon octicon-link\"></span></a>bar</h2>
HTML
    assert_equal markdown_preview.wrap_preview(html.chomp),
                 read(markdown_preview.preview_file),
                 'Should contain anchor link markup in default mode'
  end

  def test_comment_mode_anchors
    write(@source_file_path, "# foo\n## bar")
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true }  )
    assert_equal markdown_preview.wrap_preview("<h1>foo</h1>\n<h2>bar</h2>"),
                 read(markdown_preview.preview_file),
                 'Should NOT contain anchor link markup in comment mode'
  end

  def test_default_mode_task_lists
    write(@source_file_path, '- [ ] task')
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview("<ul class=\"task-list\">\n<li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\" disabled> task</li>\n</ul>"),
                 read(markdown_preview.preview_file),
                 'Should contain a (disabled) task list item in default mode'
  end

  def test_comment_mode_task_lists
    write(@source_file_path, '- [ ] task')
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    assert_equal markdown_preview.wrap_preview("<ul class=\"task-list\">\n<li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\"> task</li>\n</ul>"),
                 read(markdown_preview.preview_file),
                 'Should contain a task list item in comment mode'
  end

  def test_double_spaced_task_lists
    write(@source_file_path, "- [ ] one\n\n- [ ] two")
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    html = <<HTML
<ul class=\"task-list\">
<li class=\"task-list-item\">
<p><input class=\"task-list-item-checkbox\" type=\"checkbox\"> one</p>
</li>
<li class=\"task-list-item\">
<p><input class=\"task-list-item-checkbox\" type=\"checkbox\"> two</p>
</li>
</ul>
HTML

    assert_equal markdown_preview.wrap_preview(html.chomp),
                 read(markdown_preview.preview_file),
                 'Should render tasks even if list has extra spaces (which render as <p> elements)'
  end

  def test_newlines_ignored
    write(@source_file_path, "foo\nbar")
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview("<p>foo\nbar</p>"),
                 read(markdown_preview.preview_file),
                 'Should not contain <br> for newline'
  end

  def test_comment_mode_newlines_respected
    write(@source_file_path, "foo\nbar")
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    assert_equal markdown_preview.wrap_preview("<p>foo<br>\nbar</p>"),
                 read(markdown_preview.preview_file),
                 'Should insert <br> for newline in comment mode'
  end

  def test_at_mentions_not_linked
    write(@source_file_path, "@username")
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview("<p>@username</p>"),
                 read(markdown_preview.preview_file),
                 '@mentions should not be linked'
  end

  def test_comment_mode_at_mentions_linked
    write(@source_file_path, "@username")
    markdown_preview = @ghp.new( @source_file_path, { :comment_mode => true } )
    assert_equal markdown_preview.wrap_preview('<p><a href="https://github.com/username" class="user-mention">@username</a></p>'),
                 read(markdown_preview.preview_file),
                 '@mentions should create links'
  end

  def test_wrapper_markup_included
    write(@source_file_path, 'foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview("<p>foo</p>"),
                 read(markdown_preview.preview_file),
                 'Wrapper markup should be in preview file'
  end


  def test_uses_syntax_highlighting
    write(@source_file_path, "```ruby\nnil\n```")
    markdown_preview = @ghp.new( @source_file_path )

    assert_equal markdown_preview.wrap_preview("<pre lang=\"ruby\" class=\"highlight highlight-ruby\"><span class=\"kp\">nil</span>\n</pre>"),
                 read(markdown_preview.preview_file),
                 'Decorated code should be in preview file'
  end

  def test_update_preview
    write(@source_file_path, 'foo')
    markdown_preview = @ghp.new( @source_file_path )
    assert_equal markdown_preview.wrap_preview('<p>foo</p>'),
                 read(markdown_preview.preview_file),
                 'Preview should be initially rendered correctly'

    write(@source_file_path, 'foo bar')
    markdown_preview.update
    assert_equal markdown_preview.wrap_preview('<p>foo bar</p>'),
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
    write(@source_file_path, 'foo')
    markdown_preview = @ghp.new( @source_file_path )
    updated_by_watch = false
    markdown_preview.on_update { updated_by_watch = true }
    markdown_preview.watch

    wait_for_async_operation {
      write(@source_file_path, 'foo bar')
      updated_by_watch
    }

    markdown_preview.end_watch

    assert_equal markdown_preview.wrap_preview('<p>foo bar</p>'),
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

  def test_custom_preview_file
    write(@source_file_path, 'foo')
    custom_preview = File.join(Dir.tmpdir, 'custom_preview.html')
    markdown_preview = @ghp.new( @source_file_path, { :preview_file => custom_preview} )
    assert_equal custom_preview,
                 markdown_preview.preview_file
    assert_equal markdown_preview.wrap_preview("<p>foo</p>"),
                 read(markdown_preview.preview_file),
                 'Should write to the custom preview file'
  end

end
