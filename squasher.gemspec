# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'squasher/version'

Gem::Specification.new do |spec|
  spec.name          = "squasher"
  spec.version       = Squasher::VERSION
  spec.authors       = ["Sergey Pchelintsev"]
  spec.email         = ["linz.sergey@gmail.com"]
  spec.description   = <<-DESCRIPTION.chomp.gsub("\n", " ")
Squasher compresses old ActiveRecord migrations. On a big project with
many migrations, every rake db:migrate might take a few seconds, or creating
of a new database might take a few minutes. That's because ActiveRecord loads
all those migration files. Squasher removes all the migrations and creates a
single migration with the final database state of the specified date.
The new migration will look like a schema.rb file.
DESCRIPTION
  spec.summary       = %q{Squash your old migrations}
  spec.homepage      = "https://github.com/jalkoby/squasher"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.3.0"
end
