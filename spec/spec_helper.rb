require 'bundler/setup'
Bundler.require

def fake_root
  @fake_root ||= File.join(File.dirname(__FILE__), 'fake_app')
end

RSpec.configure do |config|
  config.order = 'random'
  config.before do
    Squasher::Config.any_instance.stub(:root_path => fake_root)
  end
end
