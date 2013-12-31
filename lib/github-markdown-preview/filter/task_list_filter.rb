require 'html/pipeline'

module GithubMarkdownPreview
  class Pipeline
    # HTML filter that replaces `[ ] task` and `[x] task` list items with "task list" checkboxes
    class TaskListFilter < HTML::Pipeline::Filter

      COMPLETE_TASK_PATTERN = /^[\s]*(\[\s\])([\s]+[^\s]*)/
      INCOMPLETE_TASK_PATTERN = /^[\s]*(\[x\])([\s]+[^\s]*)/

      def task_pattern(complete)
        task_character = complete ? 'x' : '\s'
        /^[\s]*(\[#{task_character}\])([\s]+[^\s]*)/
      end

      def task_markup(complete)
        "<input class=\"task-list-item-checkbox\" type=\"checkbox\" #{complete ? 'checked' : ''}>"
      end

      def call
        doc.search('ul/li').each do |node|
          first_child = node.children.first
          next if !first_child.text?
          content = first_child.to_html
          html = task_list_item_filter(content)
          next if html == content
          node['class'] = 'task-list-item'
          node.parent()['class'] = 'task-list'
          first_child.replace(html)
        end
        doc
      end

      # Replace "[ ]" or "[x]" with corresponding checkbox input
      def task_list_item_filter(text)
        return text unless text.include?('[ ]') || text.include?('[x]')

        [true, false].each do |complete|
          text = text.gsub task_pattern(complete) do
            task_markup(complete) + $2
          end
        end

        text
      end
    end
  end
end
