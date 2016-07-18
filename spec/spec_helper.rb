require 'bundler/setup'
Bundler.require


module SpecHelpers
  def fake_root
    File.join(File.dirname(__FILE__), 'fake_app')
  end
end

module Squasher
  class Dir < ::Dir
    def self.pwd
      File.join(File.dirname(__FILE__), 'fake_app')
    end
  end
end

RSpec.configure do |config|
  config.order = 'random'
  config.include SpecHelpers
end
