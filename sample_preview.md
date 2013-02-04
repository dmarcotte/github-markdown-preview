# Sample Local Github Markdown Preview render

Uses github css to preview not only structure and content, but also _look_ and **feel** (awkward bolding and italics for demonstration purposes)

Emoji support: :rocket:

Relative links: [readme.md](readme.md)

Syntax highlighting example courtesy of http://stackoverflow.com/a/705754
```ruby
class HelloWorld
   def initialize(name)
      @name = name.capitalize
   end
   def sayHi
      puts "Hello #{@name}!"
   end
end

hello = HelloWorld.new("World")
hello.sayHi
```