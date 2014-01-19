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

      result = under_squash_env do
        File.open(config.migration_file(finish_timestamp, :init_schema), 'wb') do |stream|
          stream << ::Squasher::Render.render(:init_schema, config)
        end

        migrations.each { |file| FileUtils.rm(file) }

        Squasher.rake("db:drop") unless Squasher.ask(:keep_database)
      end
      Squasher.clean if result && Squasher.ask(:apply_clean)
    end

    private

    def config
      @config ||= ::Squasher::Config.new
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
        if Squasher.rake("db:drop db:create", :db_create) &&
          Squasher.rake("db:migrate VERSION=#{ finish_timestamp }", :db_migrate)
          yield
        end
      end
    end
  end
end
