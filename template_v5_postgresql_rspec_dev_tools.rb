git :init
git add: "."
git commit: %Q{ -m 'Initial commit, after app ' }

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

  git add: "."
  git commit: %Q{ -m "#{message}" }
end

def add_gem_with_query(gem_name, groups, generator_command=nil)
  if yes?("Would you like to install #{gem_name}?")
    add_gem(gem_name, groups, generator_command)
  end
end

def append_to_readme(message)
  run %Q(echo "#{message}" >> README.md)
end

add_gem('rspec-rails', [:development, :test], 'rspec:install')

# gem "cucumber-rails"

after_bundle do
  git add: "."
  git commit: %Q{ -m 'Template complete.' }
end
