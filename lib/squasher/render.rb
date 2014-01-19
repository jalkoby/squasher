require 'erb'

module Squasher
  class Render
    def self.render(*args)
      new(*args).render
    end

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def render
      ERB.new(template('migration.rb'), nil, '-').result(binding)
    end

    def migration_name
      config.migration_name(:human)
    end

    def each_schema_line
      File.open(config.schema_file, 'r') do |stream|
        inside_schema = false
        stream.each_line do |line|
          if inside_schema
            next if line.empty?
            # reach eand of schema
            break if line.index("end") == 0
            yield line[2...-1]
          else
            inside_schema = true if line.include?("ActiveRecord::Schema")
          end
        end
      end
    end

    private

    def template(name)
      path = File.join(File.dirname(__FILE__), "templates/#{ name }.erb")
      template = File.open(path, "rb")
      content = template.read
      template.close
      content
    end
  end
end
