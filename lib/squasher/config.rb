require 'fileutils'
require 'yaml'

module Squasher
  class Config
    def initialize(root_path)
      @root_path = root_path
    end

    def schema_file
      @schema_file ||= root_path('db', 'schema.rb')
    end

    def migration_files
      Dir.glob(File.join(migrations_folder, '**.rb'))
    end

    def migration_file(version)
      File.join(migrations_folder, "#{ version }_#{ migration_name }.rb")
    end

    def migration_name(human = false)
      human ? 'InitSchema' : 'init_schema'
    end

    def migrations_folder?
      Dir.exists?(migrations_folder)
    end

    def dbconfig?
      !dbconfig.nil?
    end

    def stub_dbconfig
      return unless dbconfig?

      list = [dbconfig_file, schema_file]
      list.each do |file|
        next unless File.exists?(file)
        FileUtils.mv file, "#{ file }.sbackup"
      end
      update_dbconfig_file

      yield

    ensure
      list.each do |file|
        next unless File.exists?("#{ file }.sbackup")
        FileUtils.mv "#{ file }.sbackup", file
      end
    end

    private

    def root_path(*subfolders)
      if subfolders.empty?
        @root_path
      else
        File.join(@root_path, *subfolders)
      end
    end

    def migrations_folder
      @migrations_folder ||= root_path('db', 'migrate')
    end

    def dbconfig_file
      @dbconfig_file ||= root_path('config', 'database.yml')
    end

    def dbconfig
      return @dbconfig if defined?(@dbconfig)
      return @dbconfig = nil unless File.exists?(dbconfig_file)

      @dbconfig = YAML.load_file(dbconfig_file)['development']
      if @dbconfig && !@dbconfig.empty?
        @dbconfig['database'] = 'squasher'
        @dbconfig = { 'development' => @dbconfig }
      else
        @dbconfig = nil
      end
    end

    def update_dbconfig_file
      File.open(dbconfig_file, 'wb') { |stream| stream.write dbconfig.to_yaml }
    end
  end
end
