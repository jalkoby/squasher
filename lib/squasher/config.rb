require 'fileutils'
require 'yaml'
require 'erb'

module Squasher
  class Config
    attr_reader :schema_file

    def initialize
      root_path = Dir.pwd

      @schema_file = File.join(root_path, 'db', 'schema.rb')
      @migrations_folder = File.join(root_path, 'db', 'migrate')
      @dbconfig_file = File.join(root_path, 'config', 'database.yml')
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
        FileUtils.mv file, "#{ file }.sq"
      end

      File.open(dbconfig_file, 'wb') { |stream| stream.write dbconfig.to_yaml }

      yield

    ensure
      list.each do |file|
        next unless File.exists?("#{ file }.sq")
        FileUtils.mv "#{ file }.sq", file
      end
    end

    private

    attr_reader :migrations_folder, :dbconfig_file

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
  end
end
