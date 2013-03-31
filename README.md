# Autosaveable

This gem needs a lot of work to be a stand-along thing, but provides some basic autosave functionality for activeadmin.  It borrows *extremely* heavily from the fantastic paper_trail gem: https://github.com/airblade/paper_trail/. Originally this functionality was mixed into a custom branch of paper_trail but we opted to refactor it into a separate gem because it broke some of the basic conventions of paper_trail's data structure.

## Installation

Add this line to your application's Gemfile:

    gem 'autosaveable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install autosaveable

## Usage

1. Create a "saves" table with "item_type:string", "item_id:integer", "whodunnit:string", "object:text"
2. install this gem
3. add has_autosave to your models
4. add include AutoSaveable::ActiveAdmin to the corresponding activeadmin resources
5. write javascript and a custom controller to autosave your forms... (see the ToDos)

## Roadmap

1. Add initializers/generators/whatever to create saves table
2. Add tests
3. Add javascript and controller code

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request