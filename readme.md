# Rails Templates

Templates for `rails new --template abc`
Simple Ruby files containing DSL for adding gems/initializers etc. to your freshly created Rails project or an existing Rails project.

Try creating a new rails project with:
```shell
$ rails new test_app1 --template local/path/to/template_v5_rspec_dev_tools.rb
```
OR, directly from github
```
$ rails new test_app1 --template https://raw.githubusercontent.com/mattscilipoti/rails_templates/master/template_v5_rspec_dev_tools.rb
```
Don't forget to add the command flag for your favorite database (e.g. `--database postgresql`).


Some lesser used or invasive gems ask for permission first (e.g. devise, whenever).

I fought to separate each install into individual commits.

## References
- http://guides.rubyonrails.org/rails_application_templates.html
- http://guides.rubyonrails.org/generators.html#application-templates

## TODO:
- [X]: add_gem supports block (minimizes need for a method for each gem)
- [X]: improve generated readme.md
- [ ]: list gems to be installed, including optional
- [ ]: add linters
- [ ]: add code analyzers
