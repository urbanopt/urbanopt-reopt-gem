# *********************************************************************************
# URBANopt™, Copyright (c) 2019-2022, Alliance for Sustainable Energy, LLC, and other
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

require 'urbanopt/scenario/scenario_base'
require 'urbanopt/scenario/simulation_dir_osw'

require 'csv'
require 'fileutils'

# nodoc:
module URBANopt
  # nodoc:
  module Scenario
    class REoptScenarioCSV < ScenarioCSV
      ##
      # REoptScenarioCSV is an extension of ScenarioCSV which assigns a Simulation Mapper to each Feature in a FeatureFile using a simple CSV format.
      # The a \REopt Lite enabled CSV file has four columns 1) feature_id, 2) feature_name, 3) mapper_class_name and 4) optional reopt assumptions file name.  There is one row for each Feature.
      # A REoptScenarioCSV can be instantiated with set of assumptions to use in \REopt Lite for an optimization at the aggregated ScenarioReport level.
      # A REoptScenarioCSV is also instantiated with a +reopt_files_dir+ file directory containing all \REopt Lite assumptions files (required only if the ScenarioReport or its FeatureReports will have specified assumptions).
      #
      # [*parameters:*]
      #
      # * +name+ - _String_ - Human readable scenario name.
      # * +root_dir+ - _String_ - Root directory for the scenario, contains Gemfile describing dependencies.
      # * +run_dir+ - _String_ - Directory for simulation of this scenario, deleting run directory clears the scenario.
      # * +feature_file+ - _URBANopt::Core::FeatureFile_ - FeatureFile containing features to simulate.
      # * +mapper_files_dir+ - _String_ - Directory containing all mapper class files containing MapperBase definitions.
      # * +csv_file+ - _String_ - Path to CSV file assigning a MapperBase class to each feature in feature_file.
      # * +num_header_rows+ - _String_ - Number of header rows to skip in CSV file.
      # * +reopt_files_dir+ - _String_ - Path to folder containing default \REopt Lite assumptions JSON's.
      # * +scenario_reopt_assumptions_file_name+ - _String_ - Name of .json file in the +reopt_files_dir+ location to use in assessing the aggregated ScenarioReport in \REopt Lite.
      ##
      def initialize(name, root_dir, run_dir, feature_file, mapper_files_dir, csv_file, num_header_rows, reopt_files_dir = nil, scenario_reopt_assumptions_file_name = nil)
        super(name, root_dir, run_dir, feature_file, mapper_files_dir, csv_file, num_header_rows)

        @reopt_files_dir = reopt_files_dir
        @reopt_feature_assumptions = []
        @scenario_reopt_assumptions_file = nil

        if !reopt_files_dir.nil? && !scenario_reopt_assumptions_file_name.nil?
          @scenario_reopt_assumptions_file = File.join(@reopt_files_dir, scenario_reopt_assumptions_file_name)
        end
      end
      # Path to json files of reopt assumptions for feature reports ordered by feature order
      attr_accessor :reopt_feature_assumptions

      # Path to json file of reopt assumptions for scenario report
      attr_reader :scenario_reopt_assumptions_file #:nodoc:

      # Gets all the simulation directories
      def simulation_dirs
        # DLM: TODO use HeaderConverters from CSV module
        rows_skipped = 0
        result = []
        CSV.foreach(@csv_file).with_index do |row, idx|
          if rows_skipped < @num_header_rows
            rows_skipped += 1
            next
          end

          break if row[0].nil?

          # gets +feature_id+ , +feature_name+ and +mapper_class+ from csv_file
          feature_id = row[0].chomp
          feature_name = row[1].chomp
          mapper_class = row[2].chomp
          # Assume fourth columns, if exists, contains the name of the JSON file in the reopt_files_dir to use when running \REopt Lite for the feature report

          if row.length > 3 && !@reopt_files_dir.nil?
            @reopt_feature_assumptions[idx - 1] = File.join(@reopt_files_dir, row[3].chomp)
          end
          
          # gets +features+ from the feature_file.
          features = []
          feature = feature_file.get_feature_by_id(feature_id)
          features << feature

          feature_names = []
          feature_names << feature_name
          simulation_dir = SimulationDirOSW.new(self, features, feature_names, mapper_class)

          result << simulation_dir
        end
        return result
      end
    end
  end
end
