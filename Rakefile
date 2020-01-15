require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# Load in the rake tasks from the base openstudio-extension gem
require 'openstudio/extension/rake_task'
require 'urbanopt/reopt/extension'
os_extension = OpenStudio::Extension::RakeTask.new
os_extension.set_extension_class(URBANopt::REopt::Extension)

desc 'CLI OpenSSL test'
task :cli_openssl_test do
  runner = OpenStudio::Extension::Runner.new(URBANopt::REopt::Extension.new.root_dir)

  cli = OpenStudio.getOpenStudioCLI
  the_call = "#{cli} --verbose --bundle '#{runner.gemfile_path}' --bundle_path '#{runner.bundle_install_path}' ./spec/cli_openssl_test.rb"

  puts 'SYSTEM CALL:'
  puts the_call
  STDOUT.flush
  result = runner.run_command(the_call)
  puts "DONE, result = #{result}"
  STDOUT.flush
end

task default: :spec
