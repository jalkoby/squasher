module Squasher
  extend self

  autoload :Cleaner, 'squasher/cleaner'
  autoload :Config,  'squasher/config'
  autoload :Render,  'squasher/render'
  autoload :Worker,  'squasher/worker'

  attr_reader :app_path, :root_path

  def squash(raw_date, raw_options)
    parts = raw_date.to_s.split('/').map(&:to_i)
    date = Time.new(*parts)

    options = raw_options.map do |o|
      o = o.gsub('-', '').to_sym
      unless Worker::OPTIONS.include?(o)
        tell(:wrong_option, o: o)
        error(:usage)
      end
      o
    end

    @app_path = @root_path = Dir.pwd
    # In most rails engines, the 'true' root
    # is above the dummy/test directory
    @root_path = resolve_root(@app_path) if options.delete(:e)

    Worker.process(date, options)
  end

  def clean
    Cleaner.process
  end

  def rake(command, description = nil)
    tell(description) if description
    Dir.chdir(root_path) do
      system("RAILS_ENV=development DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake #{ command }")
    end
  end

  def ask(*args)
    tell(*args)
    $stdin.gets[0].downcase == 'y'
  end

  def tell(key, options = {})
    message = messages.fetch(key.to_s)
    message = message.join("\n") if message.is_a?(Array)
    message = colorize(message)
    puts message % options
  end

  def error(*args)
    tell(*args)
    exit
  end

  private

  def messages
    return @messages if @messages

    require 'json'
    path = File.join(File.dirname(__FILE__), 'squasher/messages.json')
    @messages = JSON.load(File.open(path))
  end

  COLORS = ['red', 'green', 'yellow', 'blue'].each_with_index.inject({}) { |r, (k, i)| r.merge!(k => "03#{ i + 1 }") }

  def colorize(message)
    message.gsub(/\:(\w+)\<([^>]+)\>/) { |_| "\033[#{ COLORS[$1] }m#{ $2 }\033[039m" }
  end

  # Upwardly traverse directories
  # until we find the real app root
  # if the user has specified they're
  # in an engine's dummy root
  def resolve_root(path)
    root = Pathname.new(path).parent.to_s
    root = Pathname.new(root).parent.to_s until app_path?(root)
    root
  end

  def app_path?(path)
    Dir.glob(File.join(path, '*')).select { |file| file =~ /db|config$/ }.size == 2
  end
end
