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
        if Squasher.config.set?(:dry)
          Squasher.tell(:dry_mode_finished)
          Squasher.print(Render.render(:init_schema, config))
        else
          if config.multi_db_format == 'rails'
            config.databases.each do |database|
              clean_migrations(database)
            end
          else
            clean_migrations
          end
        end

        Squasher.rake("db:drop") unless Squasher.ask(:keep_database)
      end

      Squasher.clean if result && Squasher.ask(:apply_clean)
    end

    private

    def config
      Squasher.config
    end

    def check!
      Squasher.error(:migration_folder_missing) unless config.migrations_folders?
      Squasher.error(:dbconfig_invalid) unless config.dbconfig?

      if config.multi_db_format == 'rails'
        config.databases.each do |database|
          check_migrations_exist(database)
        end
      else
        check_migrations_exist
      end
    end

    def check_migrations_exist(database = nil)
      if migrations(database).empty?
        print_date = date.strftime("%Y/%m/%d")

        Squasher.error(:no_migrations, :date => date.strftime("%Y/%m/%d"))
      end
    end

    def migrations(database = nil)
      config.migration_files(database).select { |file| before_date?(get_timestamp(file)) }.sort
    end

    def get_timestamp(file)
      File.basename(file)[/\A\d+/]
    end

    def clean_migrations(database = nil)
      path = config.migration_file(finish_timestamp(database), :init_schema, database)
      migrations(database).each { |file| FileUtils.rm(file) } # Remove all migrations before creating the new one
      File.open(path, 'wb') { |io| io << Render.render(:init_schema, config, database) }
    end

    def before_date?(timestamp)
      @point ||= date.strftime("%Y%m%d").to_i
      return unless timestamp
      timestamp[0...8].to_i < @point
    end

    def finish_timestamp(database = nil)
      get_timestamp(migrations(database).last)
    end

    def under_squash_env
      config.stub_dbconfig do
        if Squasher.config.set?(:reuse)
          Squasher.tell(:db_reuse)
        else
          return unless Squasher.rake("db:drop db:create", :db_create)
        end

        if config.multi_db_format == 'rails'
          config.databases.each do |database|
            return unless Squasher.rake("db:migrate:#{ database } VERSION=#{ finish_timestamp(database) }", :db_migrate)
          end
        else
          return unless Squasher.rake("db:migrate VERSION=#{ finish_timestamp }", :db_migrate)
        end

        yield

        true
      end
    end
  end
end
