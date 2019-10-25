# *********************************************************************************
# URBANopt, Copyright (c) 2019, Alliance for Sustainable Energy, LLC, and other
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

require 'openstudio/extension'
require 'json'

module URBANopt
  module Scenario
    module DefaultReports
      class Extension < OpenStudio::Extension::Extension
        @@schema = nil

        # Override parent class (OpenStudio::Extension::Extension)
        def initialize
          super

          @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..', '..'))

          @instance_lock = Mutex.new
          @@schema ||= schema
        end

        # Returns the absolute path of the measures or nil if there is none, can be used when configuring OSWs.
        def measures_dir
          File.absolute_path(File.join(@root_dir, 'lib/measures/'))
        end

        # Relevant files such as weather data, design days, etc.
        # Return the absolute path of the files or nil if there is none, used when configuring OSWs
        def files_dir
          File.absolute_path(File.join(@root_dir, 'lib/urbanopt/scenario/default_reports/'))
        end

        # Doc templates are common files like copyright files which are used to update measures and other code
        # Doc templates will only be applied to measures in the current repository
        # Return the absolute path of the doc templates dir or nil if there is none
        def doc_templates_dir
          File.absolute_path(File.join(@root_dir, 'doc_templates'))
        end

        # return path to schema file
        def schema_file
          File.join(files_dir, 'schema/scenario_schema.json')
        end

        # return schema
        def schema
          @instance_lock.synchronize do
            if @@schema.nil?
              File.open(schema_file, 'r') do |f|
                @@schema = JSON.parse(f.read, symbolize_names: true)
              end
            end
          end

          @@schema
        end

        ##
        # validate data against schema
        ##
        # [parameters:]
        # +schema+ - _Hash_ - A hash of the JSON scenario_schema.
        # +data+ - _Hash_ - A hash of the data to be validated against scenario_schema.
        ##
        def validate(schema, data)
          JSON::Validator.fully_validate(schema, data)
        end

        # check if the schema is valid
        def schema_valid?
          metaschema = JSON::Validator.validator_for_name('draft6').metaschema
          JSON::Validator.validate(metaschema, @@schema)
        end

        # return detailed schema validation errors
        def schema_validation_errors
          metaschema = JSON::Validator.validator_for_name('draft6').metaschema
          JSON::Validator.fully_validate(metaschema, @@schema)
        end
      end
    end
  end
end
