require 'fileutils'
require 'yaml'
require 'erb'

module Squasher
  class Config
    def initialize
      @root_path = Dir.pwd
    end

    def schema_file
      @schema_file ||= from_root('db', 'schema.rb')
    end

    def migration_files
      Dir.glob(File.join(migrations_folder, '**.rb'))
    end

    def migration_file(timestamp, migration_name)
      File.join(migrations_folder, "#{ timestamp }_#{ migration_name }.rb")
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

    attr_reader :root_path

    def from_root(*subfolders)
      File.join(root_path, *subfolders)
    end

    def migrations_folder
      @migrations_folder ||= from_root('db', 'migrate')
    end

    def dbconfig_file
      @dbconfig_file ||= from_root('config', 'database.yml')
    end

    def dbconfig
      return @dbconfig if defined?(@dbconfig)
      return @dbconfig = nil unless File.exists?(dbconfig_file)

      begin
        content = File.read(dbconfig_file).gsub(/database: (.+)/, 'database: squasher')
        parsed_content = ERB.new(content).result(binding)
        @dbconfig = YAML.load(parsed_content)
        @dbconfig = nil unless @dbconfig.keys.include?('development')
      rescue
        @dbconfig = nil
      end
      @dbconfig
    end

    def update_dbconfig_file
      File.open(dbconfig_file, 'wb') { |stream| stream.write dbconfig.to_yaml }
    end
  end
end
