# Squasher

[![Build Status](https://travis-ci.org/jalkoby/squasher.png?branch=master)](https://travis-ci.org/jalkoby/squasher)
[![Code Climate](https://codeclimate.com/github/jalkoby/squasher.png)](https://codeclimate.com/github/jalkoby/squasher)
[![Gem Version](https://badge.fury.io/rb/squasher.png)](http://badge.fury.io/rb/squasher)

Squasher compresses old migrations in a Rails application. If you work on a big project with lots of migrations, every `rake db:migrate` might take a few seconds, or creating of a new database might take a few minutes. That's because Rails loads all those migration files. Squasher removes all the migrations and creates a single migration with the final database state of the specified date (the new migration will look like a schema).

## Installation

You should not add this to your Gemfile. Just standalone installation:

    $ gem install squasher

@Note if you use Rbenv don't forget to run `rbenv rehash`.

## Usage

Suppose your application was created a few years ago. `%app_root%/db/migrate` folder looks like this:
```bash
2009...._first_migration.rb
2009...._another_migration.rb
# and a lot of other files
2011...._adding_model_foo.rb
# few years later
2013...._removing_model_foo.rb
# and so on
```

Storing these atomic changes over time is painful and useless. It's time to archive all this stuff. Once you install the gem you can run the `squasher` command.

    $ squasher 2014 #compress all migrations which were created prior to the year 2014

You can tell `squasher` a more detailed date, for example:

    $ squasher 2013/12    #prior to December 2013
    $ squasher 2013/12/19 #prior to 19 December 2013

## Requirements

It works and was tested on Ruby 1.9.3+ and Rails 3.1+. It also requires a valid configuration in `config/database.yml` and using Ruby format in `db/schema.rb` (default Rails use-case).
If an old migration inserted data (created ActiveRecord model records) you will lose this code in the squashed migration, **BUT** `squasher` will ask you to leave a tmp database which will have all data that was inserted while migrating. Using this database you could add that data as another migration, or into `config/seed.rb` (the expected place for this stuff).

## Changelog
- 0.1.6
    - support multiple database settings ([@ppworks](https://github.com/ppworks))

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
