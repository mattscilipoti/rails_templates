require 'pry-byebug'

# For Rails 4.x, 5.x
# Style Note: using "sqiggly" heredocs for proper indentation of file contents: http://ruby-doc.org/core-2.3.0/doc/syntax/literals_rdoc.html#label-Here+Documents

# Updates AppGenerator, provides helper methods
class Rails::Generators::AppGenerator

  def add_bootstrap_with_query
    return unless yes?("Would you like to install bootstrap-sass? (y/n)")

    add_gem 'bootstrap-sass' do
      unless File.exists?('app/assets/stylesheets/application.scss')
        run 'mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss'
      end
      app_stylesheet_file_contents =  <<~FILE_CONTENTS
        // "bootstrap-sprockets" must be imported before "bootstrap" and "bootstrap/variables"
        @import "bootstrap-sprockets";
        @import "bootstrap";
        // TODO: we recommend converting any `*=require...` statements to @import
      FILE_CONTENTS
      append_to_file('app/assets/stylesheets/application.scss',app_stylesheet_file_contents)

      app_javascript_file_contents = <<~FILE_CONTENTS
        fail("TODO: Move `require bootstrap-sprockets` just after jquery")
        //= require bootstrap-sprockets
      FILE_CONTENTS
      append_to_file('app/assets/javascripts/application.js', app_javascript_file_contents)
    end

    add_gem 'simple_form', {}, 'simple_form:install --bootstrap'
  end

  def add_capistrano_with_query
    return unless yes?("Would you like to install capistrano? (y/n)")

    add_gem 'capistrano-rails' do
      git_commit('capistrano: Install/generate files.') do
        run 'bundle exec cap install' # capistrano's "generator"
      end
      git_commit('capistrano: configure for rails') do
        capfile_rails_contents = <<~FILE_CONTENTS
          # Require everything for rails (bundler, rails/assets, and rails/migrations)
          require 'capistrano/rails'
          # Or require just what you need
        FILE_CONTENTS

        inject_into_file 'Capfile', before: "# require 'capistrano/rvm'"  do
          capfile_rails_contents
        end
        inject_into_file 'config/deploy.rb', after: /# ask .branch/ do
          %(set :branch, ENV['BRANCH'] || :master)
        end
      end
    end

    if yes?("Will you deploy to passenger? (y/n)")
      add_gem('capistrano-passenger') do
        uncomment_lines 'Capfile',  %r(require 'capistrano/passenger)
      end
    end

  end

  def add_database_cleaner
    add_gem 'database_cleaner', { require: false, group: non_production_groups } do
      # enclose heredoc marker in single tics to delay string interpolation until file is processed
      seed_file_contents = <<~'FILE_CONTENTS'
        require 'database_cleaner'

        unless ENV['FORCE_SEED'] || Rails.env.development? || Rails.env.test?
          fail "Safety net: If you really want to seed the '#{Rails.env}' database, use FORCE_SEED=true"
        end

        puts "Cleaning db, via truncation..."
        DatabaseCleaner.clean_with :truncation
      FILE_CONTENTS
      append_to_file('db/seeds.rb', seed_file_contents)
    end
  end

  def add_devise_with_query
    return unless yes?("Would you like to install Devise? (y/n)")

    gem "devise"
    generate "devise:install"

    # follow devise configuration instructions
    environment %q(default_url_options = ENV.fetch('default_url_options', {host: 'localhost', port: 3000})), env: 'development'
    environment %q(config.action_mailer.default_url_options = default_url_options), env: 'development'
    environment %q(fail("TODO: Configure default_url_options.")), env: 'production'
    environment %q(config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}), env: 'production'

    route "#TODO: set root route (required by Devise)"
    route "root to: 'home#index' # req'd by devise"

    # enclose heredoc marker in single tics to delay string interpolation until file is processed
    flash_messages_file_contents = <<~'FILE_CONTENTS'
      - fail("TODO: render this partial in app/views/layouts/application.html.haml")
      -# TODO: update for bootstrap, dismissable
      -#   An example: https://gist.github.com/roberto/3344628
      %section#flashMessages.row
      -flash.each do |key, value|
        %p.flash{class: "alert-#{key}"}= value

    FILE_CONTENTS
    file 'app/views/layouts/_flash_messages.html.haml', flash_messages_file_contents

    git add: '.'
    git commit: %{ -m 'devise: Install/configure environment.' }
    
    model_name = ask('What would you like the user model to be called? [User]')
    model_name = 'User' if model_name.blank?
    generate 'devise', model_name
    rails_command 'db:migrate'
    
    git add: '.'
    git commit: %( -m "devise: configure for #{model_name}" )
  end

  # adds AND commits the gem, including generator commands
  def add_gem(gem_name, gem_options={}, generator_command=nil, &block)
    message = "Installed"
    gem gem_name, gem_options

    run_install

    if generator_command || block_given?
      message += ' and configured.'
    end

    if generator_command
      message += "\n\n- #{generator_command}"
      generate generator_command
    end

    yield if block_given?

    git add: "."
    git commit: %Q{ -m "#{gem_name}: #{message}" }
  end

  # asks if user wants to install the gem
  def add_gem_with_query(gem_name, gem_options={}, generator_command=nil, &block)
    if yes?("Would you like to install #{gem_name}? (y/n)")
      add_gem(gem_name, gem_options, generator_command, &block)
    end
  end

  def app_name
    File.dirname(__FILE__)
  end

  def append_to_readme(message)
    append_to_file 'README.md', message
  end

  def git_commit(message)
    yield
    git add: '.'
    git commit: %{ -m #{message.inspect} }
  end

  def non_production_groups
    [:development, :test]
  end

  def run_install
    run 'bundle install --quiet --retry=3'
  end

  # generate, configure, and commit
  def setup(gem_name, generator_command)
    message = "#{gem_name}: $ rails #{generator_command}"
    generate generator_command

    yield if block_given?

    git add: "."
    git commit: %Q{ -m "#{message}" }
  end
end


git :init

run_install
rails_command 'db:setup'
git add: "."
message = "Initial commit.  Generated app.  Setup database (create, migrate, seed)."
message += "\n- $ rails #{ARGV.join(' ')}"
git commit: %Q(-m "#{message}")

add_gem 'rspec-rails', { group: non_production_groups }, 'rspec:install' do
  append_to_file('spec/spec_helper.rb', 'fail("TODO: Uncomment the suggested configuration items.")')
  append_to_readme("\n\n## Specs\n\n\- `$ rspec`")
end

add_database_cleaner

add_gem 'pry-byebug', { platform: :mri, group: non_production_groups } # Call 'debug', 'byebug', or 'binding.pry' anywhere in the code to stop execution and get a debugger console
add_gem 'pry-rails', { platform: :mri, group: non_production_groups } # Rails >= 3 pry initializer (enables 'reload!' and more!)

add_gem('haml-rails', {}, 'haml:application_layout') do
  run "rm 'app/views/layouts/application.html.erb'"
end

add_gem 'figaro' do
  run 'bundle exec figaro install'
  append_to_readme("\n\n## Configured via Figaro\n\nsee: https://github.com/laserlemon/figaro")
end

add_gem 'awesome_print', { require: false, group: non_production_groups } # pretty formatting in rails console
add_gem 'sandi_meter', { require: false, group: non_production_groups } # Sandi Metz' rules

## >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
## Begin optional gems

add_bootstrap_with_query
add_capistrano_with_query
add_devise_with_query

add_gem_with_query 'guard-rspec', { require: false, group: :development } do
  run `bundle exec guard init rspec`
  append_to_readme("\n- Autospec with `$ guard`")
end

add_gem_with_query 'rails_db', { group: :development } do
  append_to_readme("\n- Rails DB GUI is available at /rails/db.  This also provides `railsdb` and `railssql`.  See https://github.com/igorkasyanchuk/rails_db")
end

add_gem_with_query 'whenever', { require: false } do # manages cron
  run `wheneverize .`
  append_to_readme("\n\n## Cron\n\n- managed by whenever gem via `config/schedule.rb`.\n- see: https://github.com/javan/whenever")
end

add_gem_with_query 'meta_request', { group: non_production_groups} do # supports a Chrome extension for Rails development
  append_to_readme("\n\n## Debugging\n\n- meta_request works with rails_panel to provide a tab in Chrome Dev Tools (https://github.com/dejan/rails_panel).")
end



after_bundle do
  git add: "."
  git commit: %Q{ -m "Last template commit. spring binstubs\n\n- $ bundle exec spring binstub --all" }

  append_to_file 'Gemfile', "\n\nfail 'TODO: Regorganize and sort this generated Gemfile.'"
end
