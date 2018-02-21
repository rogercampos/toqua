# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "toqua/version"

Gem::Specification.new do |spec|
  spec.name          = "toqua"
  spec.version       = Toqua::VERSION
  spec.authors       = ["Roger Campos"]
  spec.email         = ["roger@rogercampos.com"]

  spec.summary       = %q{Collection of small utilities for controllers in rails applications}
  spec.description   = %q{Collection of small utilities for controllers in rails applications}
  spec.homepage      = "https://github.com/rogercampos/toqua"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 4.0.0"
  spec.add_dependency "actionpack", ">= 4.0.0"
  spec.add_dependency "activerecord", ">= 4.0.0"
  spec.add_dependency "recursive-open-struct", ">= 1.0.5"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-rails"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "order_query", ">= 0.3.4"
  spec.add_development_dependency "recursive-open-struct"
end
