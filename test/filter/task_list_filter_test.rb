require 'bundler/setup'
require 'minitest/autorun'
require 'github-markdown-preview'

class HTML::Pipeline::MentionFilterTest < Minitest::Test

  def filter(html, context = nil)
    doc  = Nokogiri::HTML::DocumentFragment.parse(html)

    res  = GithubMarkdownPreview::Pipeline::TaskListFilter.call(doc, context)
    assert_same doc, res

    res.to_html
  end

  def test_filter_text_task
    html = "<ul><li>[ ] task</li></ul>"
    result  = filter(html)

    assert_equal "<ul class=\"task-list\"><li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\"> task</li></ul>",
                 result
  end

  def test_filter_text_task_done
    html = "<ul><li>[x] task</li></ul>"
    result  = filter(html)

    assert_equal "<ul class=\"task-list\"><li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\" checked> task</li></ul>",
                 result
  end

  def test_filter_tasks_with_leading_whitespace
    html = "<ul><li>   [ ] task</li></ul>"
    result  = filter(html)

    assert_equal "<ul class=\"task-list\"><li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\"> task</li></ul>",
                 result
  end

  def test_filter_rich_task
    html = "<ul><li>[ ] <em>task</em></li></ul>"
    result  = filter(html)

    assert_equal "<ul class=\"task-list\"><li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\"><em>task</em>\n</li></ul>",
                 result
  end

  def test_filter_sub_task
    html = "<ul><li>[ ] task</li><ul><li>[ ] subtask</li></ul></ul>"
    result  = filter(html)

    assert_equal "<ul class=\"task-list\">\n<li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\"> task</li>\n<ul class=\"task-list\"><li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\"> subtask</li></ul>\n</ul>",
                 result
  end

  def test_filter_combined_tasks
    html = "<ul><li>[ ] task</li><li>[x] done task</li></ul>"
    result  = filter(html)

    assert_equal "<ul class=\"task-list\">\n<li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\"> task</li>\n<li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\" checked> done task</li>\n</ul>",
                 result
  end

  def test_ignores_taskless_brackets
    html = "<ul><li>[ ]</li></ul>"
    result  = filter(html)

    assert_equal "<ul><li>[ ]</li></ul>",
                 result
  end

  def test_ignores_no_space_brackets
    html = "<ul><li>[x]nospace</li></ul>"
    result  = filter(html)

    assert_equal "<ul><li>[x]nospace</li></ul>",
                 result
  end

  def test_ignores_non_start_brackets
    html = "<ul><li>nope [ ] not a task</li></ul>"
    result  = filter(html)

    assert_equal "<ul><li>nope [ ] not a task</li></ul>",
                 result
  end

  def test_disabled_tasks
    html = "<ul><li>[ ] task</li></ul>"
    result  = filter(html, { :disabled_tasks => true })

    assert_equal "<ul class=\"task-list\"><li class=\"task-list-item\">\n<input class=\"task-list-item-checkbox\" type=\"checkbox\" disabled> task</li></ul>",
                 result
  end

end
