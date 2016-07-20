# Squasher

[![Build Status](https://travis-ci.org/jalkoby/squasher.png?branch=master)](https://travis-ci.org/jalkoby/squasher)
[![Code Climate](https://codeclimate.com/github/jalkoby/squasher.png)](https://codeclimate.com/github/jalkoby/squasher)
[![Gem Version](https://badge.fury.io/rb/squasher.png)](http://badge.fury.io/rb/squasher)

Squasher compresses old migrations in a Rails application. If you work on a big project with lots of migrations, every `rake db:migrate` might take a few seconds, or creating of a new database might take a few minutes. That's because Rails loads all those migration files. Squasher removes all the migrations and creates a single migration with the final database state of the specified date (the new migration will look like a schema).

## Installation

You should not add this to your Gemfile. Just standalone installation:

    $ gem install squasher

**@note** if you use Rbenv don't forget to run `rbenv rehash`.

## Usage

**@note** stop all preloading systems if there are present (spring, zeus, etc)

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

### Options

`-d` - execute in **dry** mode - test a squashing process without deleting old migrations. The final output will be
printed in the console.

`-r` - reuse a database from previous squashing process. The option can be used in the next cases:
  - you've run squasher in **dry** mode before and there were no errors
  - you're squashing migrations gradually. For example, you want to squash migrations from 2013 till 2015, but the
process breaks in a migration from 2014. In this situation you squash till 2014, save the squasher's
database at the end, make a patch in the broken migration and run again the suite with `-r` option. As the result
squasher will not need to create the db schema and all data from the previous migrations will be there.

## Requirements

It works and was tested on Ruby 2.0+ and Rails 3.1+. It also requires a valid configuration in `config/database.yml` and using Ruby format in `db/schema.rb` (default Rails use-case).
If an old migration inserted data (created ActiveRecord model records) you will lose this code in the squashed migration, **BUT** `squasher` will ask you to leave a tmp database which will have all data that was inserted while migrating. Using this database you could add that data as another migration, or into `config/seed.rb` (the expected place for this stuff).

## Changelog
- 0.2.0
  - add **dry** mode and ability to reuse the previous squasher database
  - improve database config processing
  - raise the minimum supported version of Ruby
- 0.1.7
  - a regression fix of the log output ([@lime](https://github.com/lime))
  - improve a multi-platform support ([@johncarney](https://github.com/johncarney))
- 0.1.6
  - support multiple database settings ([@ppworks](https://github.com/ppworks))

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
