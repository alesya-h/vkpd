# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vkpd/version'

Gem::Specification.new do |spec|
  spec.name          = "vkpd"
  spec.version       = Vkpd::VERSION
  spec.authors       = ["Ales Guzik"]
  spec.email         = ["public@aguzik.net"]
  spec.description   = %q{VKPD searches for music files on russian social network vk.com and adds/plays it with MPD.}
  spec.summary       = %q{Play any music from vk.com via MPD}
  spec.homepage      = "https://github.com/alesguzik/vkpd"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra"
  spec.add_dependency "ruby-mpd", ">= 0.2.4"
  spec.add_dependency "launchy"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "awesome_print"
end
