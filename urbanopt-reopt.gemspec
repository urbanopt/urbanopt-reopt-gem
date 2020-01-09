
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'urbanopt/reopt/version'

Gem::Specification.new do |spec|
  spec.name          = 'urbanopt-reopt'
  spec.version       = URBANopt::REopt::VERSION
  spec.authors       = ['']
  spec.email         = ['']

  spec.summary       = 'Classes and measures for utilizing the REopt Lite API within OpenStudio workflows.'
  spec.description   = 'Classes and measures for utilizing the REopt Lite API within OpenStudio workflows.'
  spec.homepage      = 'https://github.com/urbanopt/urbanopt-reopt-gem'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '12.3.1'
  spec.add_development_dependency 'rspec', '3.7.0'
  spec.add_development_dependency 'rubocop', '~> 0.54.0'

  spec.add_dependency 'openstudio-extension'
  spec.add_dependency 'urbanopt-scenario'
  spec.add_dependency 'json_pure'
  spec.add_dependency 'certified'
end
