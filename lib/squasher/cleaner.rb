require 'fileutils'

module Squasher
  class Cleaner
    MIGRATION_NAME = 'squasher_clean'

    def self.process(*args)
      new(*args).process
    end

    def process
      Squasher.error(:migration_folder_missing) unless config.migrations_folders?

      if config.multi_db_format == 'rails'
        config.databases.each do |database|
          process_database(database)
        end
      else
        process_database
      end
    end

    def process_database(database = nil)
      migration_file = config.migration_file(now_timestamp, MIGRATION_NAME, database)
      if (prev_migration = prev_migration(database))
        FileUtils.rm(prev_migration)
      end
      File.open(migration_file, 'wb') do |stream|
        stream << ::Squasher::Render.render(MIGRATION_NAME, config)
      end

      if database.nil?
        Squasher.rake("db:migrate", :db_cleaning)
      else
        Squasher.rake("db:migrate:#{database}", :db_cleaning)
      end
    end

    private

    def config
      Squasher.config
    end

    def prev_migration(database = nil)
      return @prev_migration if defined?(@prev_migration)

      @prev_migration = config.migration_files(database).detect do |file|
        File.basename(file).include?(MIGRATION_NAME)
      end
    end

    def now_timestamp
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    end
  end
end
