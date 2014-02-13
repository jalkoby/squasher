# Squasher

[![Build Status](https://travis-ci.org/jalkoby/squasher.png?branch=master)](https://travis-ci.org/jalkoby/squasher)
[![Code Climate](https://codeclimate.com/github/jalkoby/squasher.png)](https://codeclimate.com/github/jalkoby/squasher)
[![Gem Version](https://badge.fury.io/rb/squasher.png)](http://badge.fury.io/rb/squasher)

Squasher is a compressor of the old migrations in a rails application. If you work on the big project with lots of migrations every `rake db:migrate` takes a few seconds, creating of a new database might takes a few minutes. It's just because rails loads all this files. Squasher instead removes all this migrations and creates a single migration with a final database state of the specified date(a new migration will look like a schema).

## Installation

You should not add this to Gemfile. Just standalone installation:

    $ gem install squasher

@Note if you use Rbenv don't forget to run `rbenv rehash`.

## Usage

Suppose your application was created a few years ago. `%app_root%/db/migrate` folder is like below list: 
```bash
2009...._first_migration.rb
2009...._another_migration.rb
# and a lot of other files
2011...._adding_model_foo.rb
# few years later
2013...._removing_model_foo.rb
# and so one
```

Storing this atomic changes with time is more painful and useles. It's time to archive all this stuff. Once you install gem you will get `squasher` command.

    $ squasher 2014 #compress all migrations which were created prior to 2014 year

You can tell `squasher` a more detailed date, for example:

    $ squasher 2013/12    #prior December 2013
    $ squasher 2013/12/19 #prior 19 December 2013

## Requirements

It works and was tested on Ruby 1.9.3+ and Rails 3.1+. Also it requires a valid configuration in `config/database.yml` and using Ruby format in `db/schema.rb`(default rails use-case).
If a some migration insert data(create a ActiveRecord model records) you will lost this code in a new created migration, **BUT** `squasher` will ask you to leave a tmp database which will have all inserted information. Using this database you could again add this inserting into a new migration or create/update `config/seed.rb` file(expected place for this stuff).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
