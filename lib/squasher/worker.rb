require 'fileutils'

module Squasher
  class Worker
    OPTIONS = [:d, :r]

    attr_reader :date, :options

    def self.process(*args)
      new(*args).process
    end

    def initialize(date, options = [])
      @date = date
      @options = options
    end

    def process
      check!

      result = under_squash_env do
        if options.include?(:d)
          Squasher.tell(:dry_mode_finished)
          puts Render.render(:init_schema, config)
        else
          path = config.migration_file(finish_timestamp, :init_schema)
          File.open(path, 'wb') { |io| io << Render.render(:init_schema, config) }
          migrations.each { |file| FileUtils.rm(file) }
        end

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

      @migrations = config.migration_files.select { |file| before_date?(get_timestamp(file)) }.sort
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
        if options.include?(:r)
          Squasher.tell(:db_reuse)
        else
          return unless Squasher.rake("db:drop db:create", :db_create)
        end

        return unless Squasher.rake("db:migrate VERSION=#{ finish_timestamp }", :db_migrate)

        yield

        true
      end
    end
  end
end
