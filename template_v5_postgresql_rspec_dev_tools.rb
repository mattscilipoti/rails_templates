require 'pry-byebug'


class Rails::Generators::AppGenerator
  def add_database_cleaner
    add_gem 'database_cleaner', { require: false, group: non_production_groups } do
      append_to_file('db/seeds.rb',
      %q(
require 'database_cleaner'

unless ENV['FORCE_SEED'] || Rails.env.development? || Rails.env.test?
  fail "Safety net: If you really want to seed the '#{Rails.env}' database, use FORCE_SEED=true"
end

puts "Cleaning db, via truncation..."
DatabaseCleaner.clean_with :truncation
)
      )
    end
  end

  def add_devise
    return unless yes?("Would you like to install Devise?")

    gem "devise"
    generate "devise:install"

    # follow devise configuration instructions
    environment %q(default_url_options = ENV.fetch('default_url_options', {host: 'localhost', port: 3000})), env: 'development'
    environment %q(config.action_mailer.default_url_options = default_url_options), env: 'development'
    environment %q(fail("TODO: Configure default_url_options.")), env: 'production'
    environment %q(config.action_mailer.default_url_options = {host: "http://yourwebsite.example.com"}), env: 'production'

    route "#TODO: set root route (required by Devise)"
    route "root to: 'home#index' # req'd by devise"

    file 'app/views/layouts/_flash_messages.html.haml',
    %q(
    fail("TODO: render this partial in app/views/layouts/application.html.haml")
    -# TODO: update for bootstrap, dismissable
    -#   An example: https://gist.github.com/roberto/3344628
    %section#flashMessages.row
    -flash.each do |key, value|
      %p.flash{class: "alert-#{key}"}= value
      )

      git add: "."
      git commit: %Q{ -m "devise: Install/configure environment." }

      model_name = ask("What would you like the user model to be called? [User]")
      model_name = "User" if model_name.blank?
      generate "devise", model_name
      rails_command "db:migrate"

      git add: "."
      git commit: %Q{ -m "devise: configure for #{model_name}" }
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
      if yes?("Would you like to install #{gem_name}?")
        add_gem(gem_name, gem_options, generator_command, &block)
      end
    end

    def app_name
      File.dirname(__FILE__)
    end

    def append_to_readme(message)
      append_to_file 'README.md', message
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
  git add: "."
  message = "Initial commit.  Generated app."
  message += "\n- $ rails #{ARGV.join(' ')}"
  git commit: %Q(-m "#{message}")

  add_gem 'rspec-rails', { group: non_production_groups }, 'rspec:install' do
    append_to_file('spec/spec_helper.rb', 'fail("TODO: Uncomment the suggested configuration items.")')
  end

  add_database_cleaner

  add_gem 'pry-byebug', { platform: :mri, group: non_production_groups } # Call 'debug', 'byebug', or 'binding.pry' anywhere in the code to stop execution and get a debugger console
  add_gem 'pry-rails', { platform: :mri, group: non_production_groups } # Rails >= 3 pry initializer (enables 'reload!' and more!)

  add_gem('haml-rails', {}, 'haml:application_layout') do
    run "rm 'app/views/layouts/application.html.erb'"
  end

  add_gem 'figaro' do
    run 'bundle exec figaro install'
    append_to_readme("\n## Configured via Figaro\n\nsee: https://github.com/laserlemon/figaro")
  end

  add_devise

  add_gem 'sandi_meter', { require: false, group: non_production_groups } # Sandi Metz' rules



  after_bundle do
    git add: "."
    git commit: %Q{ -m "Last template commit. spring binstubs\n\n- $ bundle exec spring binstub --all" }

    append_to_file 'Gemfile', "\n\nfail 'TODO: Regorganize and sort this generated Gemfile.'"
  end
