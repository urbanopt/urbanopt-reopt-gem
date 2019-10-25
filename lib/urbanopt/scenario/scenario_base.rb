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

module URBANopt
  module Scenario
    # ScenarioBase is a simulation method agnostic description of a Scenario.
    class ScenarioBase
      ##
      # Initialize ScenarioBase attributes: +name+ , +root directory+ , +run directory+ and +feature_file+
      ##
      # [parameters:]
      # +name+ - _String_ - Human readable scenario name.  
      # +root_dir+ - _String_ - Root directory for the scenario, contains Gemfile describing dependencies.  
      # +run_dir+ - _String_ - Directory for simulation of this scenario, deleting run directory clears the scenario.  
      # +feature_file+ - _FeatureFile_ - An instance of +URBANopt::Core::FeatureFile+ containing features for simulation.  
      def initialize(name, root_dir, run_dir, feature_file)
        @name = name
        @root_dir = root_dir
        @run_dir = run_dir
        @feature_file = feature_file
      end

      ##
      # Name of the Scenario.
      attr_reader :name #:nodoc:

      ##
      # Root directory containing Gemfile.
      attr_reader :root_dir #:nodoc:

      ##
      # Directory to run this Scenario.
      attr_reader :run_dir #:nodoc:

      ##
      # An instance of +URBANopt::Core::FeatureFile+ associated with this Scenario.
      attr_reader :feature_file #:nodoc:

      # An array of SimulationDirBase objects.
      def simulation_dirs
        raise 'simulation_dirs not implemented for ScenarioBase, override in your class'
      end

      # Removes all simulation input and output files by removing this Scenario's +run_dir+ .
      def clear
        Dir.glob(File.join(@run_dir, '/*')).each do |f|
          FileUtils.rm_rf(f)
        end
      end
    end
  end
end
