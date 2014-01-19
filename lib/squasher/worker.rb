require 'fileutils'

module Squasher
  class Worker
    attr_reader :date

    def self.process(*args)
      new(*args).process
    end

    def initialize(date)
      @date = date
    end

    def process
      check!

      under_squash_env do
        File.open(config.migration_file(finish_timestamp), 'wb') do |stream|
          stream << ::Squasher::Render.render(config)
        end

        migrations.each { |file| FileUtils.rm(file) }

        rake("db:drop") unless Squasher.ask(:keep_database)
      end
    end

    private

    def config
      @config ||= ::Squasher::Config.new(Dir.pwd)
    end

    def check!
      Squasher.error(:migration_folder_missing) unless config.migrations_folder?
      Squasher.error(:dbconfig_invalid) unless config.dbconfig?
      if migrations.empty?
        print_date = date.strftime("%Y/%m/%d")
        Squasher.error(:no_migrations, :date => print_date)
      end
    end

    def migrations
      return @migrations if @migrations

      @migrations = config.migration_files.select { |file| before_date?(get_timestamp(file)) }
    end

    def get_timestamp(file)
      File.basename(file)[/\A\d+/]
    end

    def before_date?(timestamp)
      @point ||= date.strftime("%Y%m%d").to_i
      return unless timestamp
      timestamp[0...8].to_i < @point
    end

    def finish_timestamp
      @finish_timestamp ||= get_timestamp(migrations.last)
    end

    def under_squash_env
      config.stub_dbconfig do
        if rake("db:drop db:create", :db_create) && rake("db:migrate VERSION=#{ finish_timestamp }", :db_migrate)
          yield
        end
      end
    end

    def rake(command, description = nil)
      Squasher.tell(description) if description
      system("bundle exec rake #{ command }")
    end
  end
end
