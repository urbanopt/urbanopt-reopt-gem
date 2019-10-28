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

require 'urbanopt/scenario/scenario_post_processor_base'
require 'urbanopt/scenario/default_reports'
require 'urbanopt/scenario/default_reports/logger'

require 'csv'
require 'json'
require 'fileutils'

module URBANopt # nodoc:
  module Scenario  # nodoc:
    class ScenarioDefaultREoptPostProcessor < ScenarioDefaultPostProcessor
      ##
      # ScenarioDefaultREoptPostProcessor is an extension of a URBANopt::Scenario::ScenarioDefaultPostProcessor which populates default directory names for future \REopt Lite analyses.
      ##
      # [*parameters:*]
      #
      # *+scenario_base+ - _URBANopt:Scenario:ScenarioBase - An object of ScenarioBase class. 
      def initialize(scenario_base)
        super(scenario_base)
        @scenario_reopt_default_assumptions_hash = nil
        @scenario_reopt_default_output_file = nil
        @scenario_timeseries_default_output_file = nil
        @feature_reports_reopt_default_assumption_hashes = []
        @feature_reports_reopt_default_output_files = []
        @feature_reports_timeseries_default_output_files =[]
      end

      attr_accessor :scenario_reopt_default_assumptions_hash, :scenario_reopt_default_output_file, :scenario_timeseries_default_output_file
      attr_accessor :feature_reports_reopt_default_assumption_hashes, :feature_reports_reopt_default_output_files, :feature_reports_timeseries_default_output_files
      ##
      # Run the post processor on this Scenario.This will add all the simulation_dirs and populate default \REopt Lite file names.
      ##
      def run
        # this run method adds all the simulation_dirs, you can extend it to do more custom stuff
        @scenario_base.simulation_dirs.each do |simulation_dir|
          add_simulation_dir(simulation_dir)
        end
          @scenario_reopt_default_output_file = File.join(@scenario_result.directory_name, "scenario_report_#{@scenario_result.id}_reopt_run.json")
          @scenario_timeseries_default_output_file = File.join(@scenario_result.directory_name, "scenario_report_#{@scenario_result.id}_timeseries.csv")
          
          File.open(baseline_scenario.scenario_reopt_assumptions_file, 'r') do |file|
            @scenario_reopt_default_assumptions_hash = JSON.parse(file.read, symbolize_names: true)
          end

          @scenario_base.reopt_feature_assumptions.each do |file|
            @feature_reports_reopt_default_assumption_hashes << JSON.parse(File.open(file,'r').read, symbolize_names: true)    
          end

          @scenario_result.feature_reports.each do |fr|
            @feature_reports_reopt_default_output_files << File.join(fr.directory_name, "feature_report_#{fr.id}_reopt_run.json")
          end

          @scenario_result.feature_reports.each do |fr|
            @feature_reports_timeseries_default_output_files << File.join(fr.directory_name, "feature_report_#{fr.id}_timeseries.csv")
          end

        return @scenario_result
      end
    end
  end
end
