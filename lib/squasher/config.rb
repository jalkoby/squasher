require 'fileutils'
require 'yaml'
require 'erb'

module Squasher
  class Config
    attr_reader :schema_file

    def initialize
      app_path = Squasher.app_path || Dir.pwd

      @schema_file = File.join(app_path, 'db', 'schema.rb')
      @migrations_folder = File.join(Squasher.root_path || app_path, 'db', 'migrate')
      @dbconfig_file = File.join(app_path, 'config', 'database.yml')
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

      @dbconfig = nil

      begin
        content = YAML.load(ERB.new(File.read(dbconfig_file)).result(binding))
        if content.has_key?('development')
          @dbconfig = { 'development' => content['development'].merge('database' => 'squasher') }
        end
      rescue
      end
      @dbconfig
    end
  end
end
