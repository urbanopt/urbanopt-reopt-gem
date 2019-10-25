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
    class ScenarioRunnerBase
      ##
      # ScenarioRunnerBase is the agnostic interface for a class which can create and run SimulationFiles.
      ##
      def initialize; end

      ##
      # Create all SimulationDirs for Scenario.
      ##
      # [parameters:]
      # +scenario+ - _ScenarioBase_ - Scenario to create simulation input files for scenario.  
      # +force_clear+ - _Bool_ - Clear Scenario before creating simulation input files  
      # [return:] _Array_ Returns an array of all SimulationDirs, even those created previously, for Scenario.
      def create_simulation_files(scenario, force_clear = false)
        raise 'create_input_files is not implemented for ScenarioRunnerBase, override in your class'
      end

      ##
      # Create and run all SimulationFiles for Scenario.
      ##
      # [parameters:]
      # +scenario+ - _ScenarioBase_ - Scenario to create and run simulation input files for.    
      # +force_clear+ - _Bool_ - Clear Scenario before creating Simulation input files.    
      # 
      # [return:] _Array_ Returns an array of all SimulationDirs, even those created previously, for Scenario.
      def run(scenario, force_clear = false)
        raise 'run is not implemented for ScenarioRunnerBase, override in your class'
      end
    end
  end
end
