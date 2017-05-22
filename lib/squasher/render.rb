require 'erb'

module Squasher
  class Render
    def self.render(*args)
      new(*args).render
    end

    attr_reader :name, :config

    def initialize(name, config)
      @name = name
      @config = config
    end

    def render
      ERB.new(template("#{ name }.rb"), nil, '-').result(binding)
    end

    def each_schema_line
      File.open(config.schema_file, 'r') do |stream|
        inside_schema = false
        stream.each_line do |line|
          if inside_schema
            # reach the end of schema
            break if line.index("end") == 0
            yield line.gsub(/\A\s{,2}(.*)\s+\z/, '\1')
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
