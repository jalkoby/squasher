# Squasher

[![Build Status](https://travis-ci.org/jalkoby/squasher.png?branch=master)](https://travis-ci.org/jalkoby/squasher)
[![Code Climate](https://codeclimate.com/github/jalkoby/squasher.png)](https://codeclimate.com/github/jalkoby/squasher)
[![Gem Version](https://badge.fury.io/rb/squasher.png)](http://badge.fury.io/rb/squasher)

Squasher is a compressor of the old migrations in rails application. If you works on big project with lots of migrations
every `rake db:migrate` takes a few seconds, creating of a new database might takes a few minutes. It's just because rails load
all this files. Squasher instead remove all this migrations and create one single migration with a final state of a database.

## Installation

You should not add this to Gemfile. Just standalone installation:

    $ gem install squasher

@Note if you use Rbenv don't forget to run `rbenv rehash`.

## Usage

Once you install gem you will get `squasher` command.

    $ squasher 2014 #compress all migrations which were created prior to 2014 year

You can tell `squasher` a more detailed date, for example:

    $ squasher 2013/12    #prior December 2013
    $ squasher 2013/12/19 #prior 19 December 2013

## Requirements

It works and was tested on Ruby 1.9.3+ and Rails 3.2+. Also it requires a valid configuration in `config/database.yml` and using Ruby format in `db/schema.rb`(default rails usecase).
If some migration insert data(create a ActiveRecord model records) you will lost this code in a new created migration, but `squasher` will ask you to leave tmp database which will have all inserted information. Using this database you could again add this inserting into a new migration or create/update `config/seed.rb` file(expected place for this stuff).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
