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

require 'urbanopt/scenario/scenario_runner_base'
require 'json'

require 'fileutils'
# require 'hash_parser'

module URBANopt
  module Scenario
    class ScenarioRunnerOSW < ScenarioRunnerBase
      ##
      # ScenarioRunnerOSW is a class to create and run SimulationFileOSWs
      ##
      def initialize; end

      ##
      # Create all OSWs for Scenario.
      ##
      # [parameters:]
      # +scenario+ - _ScenarioBase_ - Scenario to create simulation input files for.   
      # +force_clear+ - _Bool_ - Clear Scenario before creating simulation input files.  
      # [return:] _Array_ Returns array of all SimulationDirs, even those created previously, for Scenario.
      def create_simulation_files(scenario, force_clear = false)
        if force_clear
          scenario.clear
        end

        FileUtils.mkdir_p(scenario.run_dir) if !File.exist?(scenario.run_dir)

        simulation_dirs = scenario.simulation_dirs

        simulation_dirs.each do |simulation_dir|
          if simulation_dir.out_of_date?
            puts "simulation_dir #{simulation_dir.run_dir} is out of date, regenerating input files"
            simulation_dir.create_input_files
          end
        end
        return simulation_dirs
      end

      ##
      # Create and run all SimulationFileOSW for Scenario.
      # A staged runner is implented to run buildings, then transformers then district systems.
      # - instantiate openstudio runner to run .osw files.
      # - create simulation files for this scenario.
      # - get feature_type value from in.osw files
      # - cretae 3 groups to store .osw files (+building_osws+ , +transformer_osws+ , +district_system_osws+)
      # - add each osw file to its corresponding group id +simulation_dir+ is out_of_date
      # - Run osw file groups in order and store simulation failure in a array.
      ##
      # [parameters:]
      # +scenario+ - _ScenarioBase_ - Scenario to create and run SimulationFiles for.    
      # +force_clear+ - _Bool_ - Clear Scenario before creating SimulationFiles.    
      # [return:] _Array_ Returns array of all SimulationFiles, even those created previously, for Scenario.
      def run(scenario, force_clear = false)

        # instantiate openstudio runner
        runner = OpenStudio::Extension::Runner.new(scenario.root_dir)

        # create simulation files
        simulation_dirs = create_simulation_files(scenario, force_clear)

        # osws = []
        # simulation_dirs.each do |simulation_dir|
        #   if !simulation_dir.is_a?(SimulationDirOSW)
        #     raise "ScenarioRunnerOSW does not know how to run #{simulation_dir.class}"
        #   end
        #   if simulation_dir.out_of_date?
        #     osws << simulation_dir.in_osw_path
        #   end
        # end

        # cretae 3 groups to store .osw files (+building_osws+ , +transformer_osws+ , +district_system_osws+)
        building_osws = []
        transformer_osws = []
        district_system_osws = []

        simulation_dirs.each do |simulation_dir|
          in_osw = File.read(simulation_dir.in_osw_path)
          in_osw_hash = JSON.parse(in_osw, symbolize_names: true)

          if !simulation_dir.is_a?(SimulationDirOSW)
            raise "ScenarioRunnerOSW does not know how to run #{simulation_dir.class}"
          end

          # get feature_type value from in.osw files
          feature_type = nil
          in_osw_hash[:steps].each { |x| feature_type = x[:arguments][:feature_type] if x[:arguments][:feature_type] }

          # add each osw file to its corresponding group id +simulation_dir+ is out_of_date
          if simulation_dir.out_of_date?

            if feature_type == 'Building'
              building_osws << simulation_dir.in_osw_path
            elsif feature_type == 'District System'
              district_system_osws << simulation_dir.in_osw_path
            elsif feature_type == 'Transformer'
              transformer_osws << simulation_dir.in_osw_path
            else
              raise "ScenarioRunnerOSW does not know how to run a #{feature_type} feature"
            end

          end
        end

        # Run osw groups in order and store simulation failure in a array.
        # Return simulation_dirs after running all simulations.

        # failures 
        failures = []
        # run building_osws
        building_failures = runner.run_osws(building_osws, num_parallel = Extension::NUM_PARALLEL, max_to_run = Extension::MAX_DATAPOINTS)
        failures << building_failures
        # run district_system_osws
        district_system_failures = runner.run_osws(district_system_osws, num_parallel = Extension::NUM_PARALLEL, max_to_run = Extension::MAX_DATAPOINTS)
        failures << district_system_failures
        # run transformer_osws
        transformer_failures = runner.run_osws(transformer_osws, num_parallel = Extension::NUM_PARALLEL, max_to_run = Extension::MAX_DATAPOINTS)
        failures << transformer_failures

        # puts "failures = #{failures}"
        return simulation_dirs
      end
    end
  end
end
