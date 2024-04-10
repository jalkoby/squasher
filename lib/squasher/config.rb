require 'fileutils'
require 'yaml'
require 'erb'

module Squasher
  class Config
    module Render
      extend self

      def process(path)
        @error = false
        # Support for Psych 4 (the default yaml parser for Ruby 3.1)
        opts = Gem::Version.new(Psych::VERSION).segments.first < 4 ? {} : { aliases: true }
        str = YAML.load(ERB.new(File.read(path)).result(binding), **opts)
        [str, @error]
      end

      def method_missing(*args)
        @error = true
        self
      end

      def const_missing(*args)
        @error = true
        self
      end

      def to_s
        ''
      end

      def inspect
        ''
      end
    end

    attr_reader :migration_version, :multi_db_format, :databases

    def initialize
      @root_path = Dir.pwd.freeze
      @flags = []
      @multi_db_format = nil
      @databases = []
      set_app_path(@root_path)
    end

    def set(key, value)
      if key == :engine
        base = value.nil? ? @root_path : File.expand_path(value, @root_path)
        list = Dir.glob(File.join(base, '**', '*', 'config', 'application.rb'))
        case list.size
        when 1
          set_app_path(File.expand_path('../..', list.first))
        when 0
          Squasher.error(:cannot_find_dummy, base: base)
        else
          Squasher.error(:multi_dummy_case, base: base)
        end
      elsif key == :migration
        Squasher.error(:invalid_migration_version, value: value) unless value.to_s =~ /\A\d.\d\z/
        @migration_version = "[#{value}]"
      elsif key == :multi_db_format
        Squasher.error(:invalid_multi_db_format, value: value) unless %w[rails multiverse].include?(value)
        @multi_db_format = value
      elsif key == :databases
        @databases = value
      else
        @flags << key
      end
    end

    def set?(k)
      @flags.include?(k)
    end

    def schema_files
      return [schema_file] unless @multi_db_format == 'rails'

      @databases.map { |db| schema_file(db) }
    end

    def schema_file(database = nil)
      prefix = database.nil? || database == 'primary' ? '' : "#{ database }_"
      file = set?(:sql) ? 'structure.sql' : 'schema.rb'

      File.join(@app_path, 'db', "#{ prefix }#{ file }")
    end

    def migration_files(database = nil)
      Dir.glob(File.join(migrations_folder(database), '**.rb'))
    end

    def migration_file(timestamp, migration_name, database = nil)
      File.join(migrations_folder(database), "#{ timestamp }_#{ migration_name }.rb")
    end

    def migrations_folder(database = nil)
      return default_migration_folder if database.nil?

      migrations_paths = dbconfig['development'][database]['migrations_paths']
      return default_migration_folder unless migrations_paths

      File.join(@app_path, migrations_paths)
    end

    def migrations_folders?
      if @multi_db_format != 'rails'
        Dir.exist?(migrations_folder)
      else
        @databases.all? { |db| Dir.exist?(migrations_folder(db)) }
      end
    end

    def default_migration_folder
      File.join(@root_path, 'db', 'migrate')
    end

    def dbconfig?
      !dbconfig.nil?
    end

    def stub_dbconfig
      return unless dbconfig?

      list = [dbconfig_file, *schema_files]
      list.each do |file|
        next unless File.exist?(file)
        FileUtils.mv file, "#{ file }.sq"
      end

      File.open(dbconfig_file, 'wb') { |stream| stream.write dbconfig.to_yaml }

      yield

    ensure
      list.each do |file|
        next unless File.exist?("#{ file }.sq")
        FileUtils.mv "#{ file }.sq", file
      end
    end

    def in_app_root(&block)
      Dir.chdir(@app_path, &block)
    end

    private

    attr_reader :dbconfig_file

    def dbconfig
      return @dbconfig if defined?(@dbconfig)
      return @dbconfig = nil unless File.exist?(dbconfig_file)

      @dbconfig = nil

      begin
        content, soft_error = Render.process(dbconfig_file)
        if content.has_key?('development')
          if @multi_db_format == 'rails'
            @dbconfig = { 'development' => {} }
            @databases.each do |database|
              @dbconfig['development'][database] = content['development'][database].merge('database' => "#{database}_squasher")
              
              database_name = content['development'][database]['database']
              content['development'].select { |_, v| v['database'] == database_name && v['replica'] }.each do |k, v|
                @dbconfig['development'][k] = v.merge('database' => "#{database}_squasher")
              end
            end
          else
            @dbconfig = { 'development' => content['development'].merge('database' => 'squasher') }

            multiverse_by_default = @multi_db_format.nil? && @databases.any?
            if multiverse_by_default
              puts "Using multiverse format by default is deprecated and will be removed in the next major release. Please specify --multi-db_format=rails or --multi-db_format=multiverse explicitly."
            end
            if multiverse_by_default || @multi_db_format == 'multiverse'
              @databases&.each { |database| @dbconfig[database] = content[database] }
            end
          end
        end
      rescue
      end

      if soft_error && @dbconfig
        exit unless Squasher.ask(:use_dbconfig, config: @dbconfig.fetch('development'))
      end
      @dbconfig
    end

    def set_app_path(path)
      @app_path = path
      @dbconfig_file = File.join(path, 'config', 'database.yml')
    end
  end
end
