git :init
git add: "."
git commit: %Q{ -m 'Initial commit, after app ' }

# adds AND commits the gem, including generator commands
def add_gem(gem_name, groups, generator_command=nil, &block)
  message = "Added #{gem_name}"
  case groups
  when nil, :default
    gem gem_name
  else
    gem gem_name, group: groups
  end
  if generator_command
    message += "\n\n- #{generator_command}"
    generate generator_command
  end

  yield if block_given?

  git add: "."
  git commit: %Q{ -m "#{message}" }
end

# asks if user wants to install the gem
def add_gem_with_query(gem_name, groups, generator_command=nil, &block)
  if yes?("Would you like to install #{gem_name}?")
    add_gem(gem_name, groups, generator_command, &block)
  end
end

def append_to_readme(message)
  run %Q(echo "#{message}" >> README.md)
end

add_gem('rspec-rails', [:development, :test], 'rspec:install')

# gem "cucumber-rails"

add_gem('haml-rails', :default, 'haml:application_layout') do
  run "rm 'app/views/layouts/application.html.erb'"
end

add_gem 'figaro', :default do
  run 'bundle exec figaro install'
  append_to_readme("\n## Configured via Figaro\n\nsee: https://github.com/laserlemon/figaro")
end

after_bundle do
  git add: "."
  git commit: %Q{ -m 'Template complete.' }
end
