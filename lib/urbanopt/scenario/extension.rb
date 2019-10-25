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

module URBANopt
  module Scenario
    class Extension < OpenStudio::Extension::Extension

      # set NUM_PARALLEL 
      OpenStudio::Extension::Extension::NUM_PARALLEL = 7

      # set MAX_DATAPOINTS to
      OpenStudio::Extension::Extension::MAX_DATAPOINTS = 1000

      # set VERBOSE to true
      OpenStudio::Extension::Extension::VERBOSE = true
      
      # set DO_SIMULATIONS to true
      OpenStudio::Extension::Extension::DO_SIMULATIONS = true

      def initialize
        super
        @root_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
      end

      ##
      # Returns the absolute path of the measures or nil if there is none, can be used when configuring OSWs.
      def measures_dir
        return File.absolute_path(File.join(@root_dir, 'lib', 'measures'))
      end

      ##
      # Relevant files such as weather data, design days, etc.
      # Return the absolute path of the files or nil if there is none, used when configuring OSWs
      def files_dir
        return nil
      end

      ##
      # Doc templates are common files like copyright files which are used to update measures and other code.
      # Doc templates will only be applied to measures in the current repository.
      # Return the absolute path of the doc templates dir or nil if there is none.
      def doc_templates_dir
        return File.absolute_path(File.join(@root_dir, 'doc_templates'))
      end
    end
  end
end
