# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'henchman/version'

Gem::Specification.new do |spec|
  spec.name          = "henchman"
  spec.version       = Henchman::VERSION
  spec.authors       = ["Greg Merritt"]
  spec.email         = ["gremerritt@gmail.com"]

  spec.summary       = %q{Cloud music syncing for iTunes on OS X}
  spec.description   = %q{OS X app that sits on top of iTunes to sync music with Dropbox}
  spec.homepage      = "https://www.github.com/gremerritt/henchman"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
