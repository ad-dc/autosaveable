# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'autosaveable/version'

Gem::Specification.new do |spec|
  spec.name          = "autosaveable"
  spec.version       = Autosaveable::VERSION
  spec.authors       = ["Dan Hoerr"]
  spec.email         = ["dan.hoerr@appdirect.com"]
  spec.description   = "Enables Autosave in Doc-Center"
  spec.summary       = "Enables Autosave in Doc-Center"
  spec.homepage      = "http://www.appdirect.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
