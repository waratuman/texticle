# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "texticle"
  spec.version       = '0.0.1'
  spec.authors       = ["James R. Bracy"]
  spec.email         = ["waratuman@gmail.com"]
  spec.description   = %q{ActiveRecord extension for full text search in PostgreSQL}
  spec.summary       = %q{ActiveRecord extension for full text search in PostgreSQL}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activerecord', '~> 4.0.0'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'minitest', '>= 4.4.0'
  spec.add_development_dependency 'turn'
  spec.add_development_dependency 'sqlite3'

end
