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
    class SimulationDirBase
      ##
      # SimulationDirBase is the agnostic representation of a directory of simulation input files.
      ##
      # [parameters:]
      # +scenario+ - _ScenarioBase_ - Scenario containing this SimulationDirBase.   
      # +features+ - _Array_ - Array of Features that this SimulationDirBase represents.  
      # +feature_names+ - _Array_ - Array of scenario specific names for these Features.
      def initialize(scenario, features, feature_names)
        @scenario = scenario
        @features = features
        @feature_names = feature_names
      end

      attr_reader :scenario #:nodoc:

      attr_reader :features #:nodoc:

      attr_reader :feature_names #:nodoc:

      ##
      # Return the directory that this simulation will run in
      ##
      def run_dir
        raise 'run_dir is not implemented for SimulationFileBase, override in your class'
      end

      ##
      # Return true if the simulation is out of date (input files newer than results), false otherwise.
      # Non-existant simulation input files are out of date.
      ##
      def out_of_date?
        raise 'out_of_date? is not implemented for SimulationFileBase, override in your class'
      end

      ##
      #  Returns simulation status one of {'Not Started', 'Started', 'Complete', 'Failed'}
      ##
      def simulation_status
        raise 'simulation_status is not implemented for SimulationFileBase, override in your class'
      end

      ##
      # Clear the directory that this simulation runs in
      ##
      def clear
        raise 'clear is not implemented for SimulationFileBase, override in your class'
      end

      ##
      # Create run directory and generate simulation inputs, all previous contents of directory are removed
      ##
      def create_input_files
        raise 'create_input_files is not implemented for SimulationFileBase, override in your class'
      end
    end
  end
end
