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


if yes?("Would you like to install Devise?")
  gem "devise"
  generate "devise:install"

  # follow devise configuration instructions
  environment %q(default_url_options = ENV.fetch('default_url_options', {host: 'localhost', port: 3000})), env: 'development'
  environment %q(config.action_mailer.default_url_options = default_url_options), env: 'development'
  environment %q(fail("TODO: Configure default_url_options.")), env: 'production'
  environment %q(config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}), env: 'production'

  route "#TODO: set root route (required by Devise)"
  route "root to: 'home#index' # req'd by devise"

  file 'app/views/layouts/_flash_messages.html.haml', %q(
    fail('TODO: render this partial in app/views/layouts/application.html.haml')
    -# TODO: update for bootstrap, dismissable
    -#   An example: https://gist.github.com/roberto/3344628
    %section#flashMessages.row
      -flash.each do |key, value|
        %p.flash{class: "alert-#{key}"}= value
  )

  git add: "."
  git commit: %Q{ -m "Install/configure devise environment." }

  model_name = ask("What would you like the user model to be called? [User]")
  model_name = "User" if model_name.blank?
  generate "devise", model_name
  rails_command "db:migrate"

  git add: "."
  git commit: %Q{ -m "Configure devise for #{model_name}" }
end

after_bundle do
  git add: "."
  git commit: %Q{ -m 'Template complete.' }
end
