require 'json'

module Squasher
  extend self

  autoload :Config, 'squasher/config'
  autoload :Render, 'squasher/render'
  autoload :Worker, 'squasher/worker'

  def squash(raw_date)
    parts = raw_date.to_s.split('/').map(&:to_i)
    date = Time.new(*parts)
    Worker.process(date)
  end

  def ask(*args)
    tell(*args)
    $stdin.gets[0].downcase == 'y'
  end

  def tell(key, options = {})
    message = messages.fetch(key.to_s)
    message = colorize(message)
    options.each { |key, value| message.gsub!(":#{ key }", value) }
    puts message
  end

  def error(*args)
    tell(*args)
    exit
  end

  private

  def messages
    return @messages if @messages
    path = File.join(File.dirname(__FILE__), 'squasher/messages.json')
    @messages = JSON.load(File.open(path))
  end

  def colorize(message)
    message.gsub(/\:(\w+)\{([^}]+)\}/) do |match|
      color_code = { "red" => "031", "green" => "032" }[$1]
      "\033[#{ color_code }m#{ $2 }\033[039m"
    end
  end
end
