source "http://rubygems.org"

# Specify your gem's dependencies
gemspec

allow_local = false

if allow_local && File.exists?('../OpenStudio-extension-gem')
  # gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
  gem 'openstudio-extension', path: '../OpenStudio-extension-gem'
else
  gem 'openstudio-extension', github: 'NREL/OpenStudio-extension-gem', branch: 'develop'
end

if allow_local && File.exists?('../urbanopt-core-gem')
  # gem 'urbanopt-core', github: 'urbanopt/urbanopt-core-gem', branch: 'develop'
  gem 'urbanopt-core', path: '../urbanopt-core-gem'
else
  gem 'urbanopt-core', github: 'urbanopt/urbanopt-core-gem', branch: 'develop'
end

 if allow_local && File.exists?('../urbanopt-scenario-gem')
   gem 'urbanopt-scenario', github: 'urbanopt/urbanopt-scenario-gem', branch: 'develop'
 else
   gem 'urbanopt-scenario', github: 'urbanopt/urbanopt-scenario-gem', branch: 'develop'
 end

gem 'openstudio_measure_tester', '= 0.1.7' # This includes the dependencies for running unit tests, coverage, and rubocop
#gem 'openstudio_measure_tester', :github => 'NREL/OpenStudio-measure-tester-gem', :ref => '273d1f1a5c739312688ea605ef4a5b6e7325332c'

# simplecov has an unneccesary dependency on native json gem, use fork that does not require this
gem 'simplecov', github: 'NREL/simplecov'

gem 'certified'
gem 'rdoc', '4.3.0'
