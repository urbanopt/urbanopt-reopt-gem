# *********************************************************************************
# URBANopt (tm), Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'
RuboCop::RakeTask.new

# Load in the rake tasks from the base openstudio-extension gem
require 'openstudio/extension/rake_task'
require 'urbanopt/reopt/extension'
os_extension = OpenStudio::Extension::RakeTask.new
os_extension.set_extension_class(URBANopt::REopt::Extension, 'urbanopt/urbanopt-reopt-gem')

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
