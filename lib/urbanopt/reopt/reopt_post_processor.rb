# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2019, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

require 'bundler/setup'
require "urbanopt/scenario/default_reports"
require "urbanopt/reopt/reopt_logger"
require 'urbanopt/reopt'
require 'csv'

module URBANopt  # :nodoc:
  module REopt  # :nodoc:
    class REoptPostProcessor
      ##
      # \REoptPostProcessor updates a ScenarioReport or FeatureReport based on \REopt Lite optimization response.
      ##
      #
      # [*parameters:*]
      #
      # * +scenario_report+ - _ScenarioReport_ - Optional. A scenario report that has been returned from the URBANopt::Scenario::ScenarioDefaultPostProcessor - used in creating default output file names in \REopt Lite optimizations.
      # * +scenario_reopt_assumptions_file+ - _String_ - Optional. JSON file formatted for a \REopt Lite analysis containing custom input parameters for optimizations at the Scenario Report level
      # * +reopt_feature_assumptions+ - _Array_ - Optional. A list of JSON file formatted for a \REopt Lite analysis containing custom input parameters for optimizations at the Feature Report level. The order and number of files must match the Feature Reports in the scenario_report input.
      # * +use_localhost+ - _Bool_ - If this is true, requests will be sent to a version of the \REopt Lite API running on localhost. Default is false, such that the production version of \REopt Lite is accessed. 
      # * +nrel_developer_key+ - _String_ - API used to access the \REopt Lite APi. Required only if +localhost+ is false. Obtain from https://developer.nrel.gov/signup/
      ##
      def initialize(scenario_report, scenario_reopt_assumptions_file=nil, reopt_feature_assumptions=[], nrel_developer_key=nil, localhost=false)
         # initialize @@logger
        @@logger ||= URBANopt::REopt.reopt_logger
        
        if reopt_feature_assumptions.nil?
          reopt_feature_assumptions = []
        end
        @nrel_developer_key = nrel_developer_key
        @localhost = localhost
        @reopt_base_post = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {},:Wind => {:max_kw => 0}}}}
        
        @scenario_reopt_default_output_file = nil
        @scenario_timeseries_default_output_file = nil
        @scenario_reopt_default_assumptions_hash = nil
        @feature_reports_reopt_default_assumption_hashes = []
        @feature_reports_reopt_default_output_files = []
        @feature_reports_timeseries_default_output_files = []

        if !scenario_report.nil?
          @scenario_report = scenario_report
          
          @scenario_reopt_default_output_file = File.join(@scenario_report.directory_name, "scenario_report_#{@scenario_report.id}_reopt_run.json")
          @scenario_timeseries_default_output_file = File.join(@scenario_report.directory_name, "scenario_report_#{@scenario_report.id}_timeseries.csv")
          
          @scenario_report.feature_reports.each do |fr|
            @feature_reports_reopt_default_output_files << File.join(fr.directory_name, "feature_report_#{fr.id}_reopt_run.json")
          end

          @scenario_report.feature_reports.each do |fr|
            @feature_reports_timeseries_default_output_files << File.join(fr.directory_name, "feature_report_#{fr.id}_timeseries.csv")
          end
        end
        
        if !scenario_reopt_assumptions_file.nil?
          File.open(scenario_reopt_assumptions_file, 'r') do |file|
            @scenario_reopt_default_assumptions_hash = JSON.parse(file.read, symbolize_names: true)
          end
        end
        
        if reopt_feature_assumptions.length != 0
          reopt_feature_assumptions.each do |file|
            @feature_reports_reopt_default_assumption_hashes << JSON.parse(File.open(file,'r').read, symbolize_names: true)    
          end
        end
      end
      
      attr_accessor :scenario_reopt_default_assumptions_hash, :scenario_reopt_default_output_file, :scenario_timeseries_default_output_file
      attr_accessor :feature_reports_reopt_default_assumption_hashes, :feature_reports_reopt_default_output_files, :feature_reports_timeseries_default_output_files
      
      ##
      # Updates a FeatureReport based on an optional set of \REopt Lite optimization assumptions. 
      ##
      #
      # [*parameters:*]
      #
      # * +feature_report+ - _URBANopt::Scenario::DefaultReports::FeatureReport_ -  FeatureReport which will be used in creating and then updated by a \REopt Lite opimization response.
      # * +reopt_assumptions_hash+ - _Hash_ - Optional. A \REopt Lite formatted hash containing default parameters (i.e. utility rate, escalation rate) which will be updated by the FeatureReport (i.e. location, roof availability)
      # * +reopt_output_file+ - _String_ - Optional. Path to a file at which REpopt Lite responses will be saved. 
      # * +timeseries_csv_path+ - _String_ - Optional. Path to a file at which the new timeseries CSV for the FeatureReport will be saved. 
      #
      # [*return:*] _URBANopt::Scenario::DefaultReports::FeatureReport_ - Returns an updated FeatureReport
      ##
      def run_feature_report(feature_report, reopt_assumptions_hash=nil, reopt_output_file=nil,timeseries_csv_path=nil)
        api = URBANopt::REopt::REoptLiteAPI.new(@nrel_developer_key, @localhost)
        adapter = URBANopt::REopt::FeatureReportAdapter.new

        reopt_input = adapter.reopt_json_from_feature_report(feature_report, reopt_assumptions_hash)
        if reopt_output_file.nil?
          reopt_output_file = feature_report.directory_name
        end
        reopt_output = api.reopt_request(reopt_input, reopt_output_file)
        return adapter.update_feature_report(feature_report, reopt_output,timeseries_csv_path)
      end

##
      # Updates a ScenarioReport based on an optional set of \REopt Lite optimization assumptions. 
      ##
      #
      # [*parameters:*]
      #
      # * +feature_report+ - _URBANopt::Scenario::DefaultReports::ScenarioReport_ -  ScenarioReport which will be used in creating and then updated by a \REopt Lite opimization response.
      # * +reopt_assumptions_hash+ - _Hash_ - Optional. A \REopt Lite formatted hash containing default parameters (i.e. utility rate, escalation rate) which will be updated by the ScenarioReport (i.e. location, roof availability)
      # * +reopt_output_file+ - _String_ - Optional. Path to a file at which REpopt Lite responses will be saved. 
      # * +timeseries_csv_path+ - _String_ - Optional. Path to a file at which the new timeseries CSV for the ScenarioReport will be saved.
      #
      # [*return:*] _URBANopt::Scenario::DefaultReports::ScenarioReport_ Returns an updated ScenarioReport
      def run_scenario_report(scenario_report, reopt_assumptions_hash=nil, reopt_output_file=nil,timeseries_csv_path=nil)
        if !reopt_assumptions_hash.nil?
          @scenario_reopt_default_assumptions_hash = reopt_assumptions_hash
        end
        if !reopt_output_file.nil?
          @scenario_reopt_default_output_file = reopt_output_file
        end
        if !timeseries_csv_path.nil?
          @scenario_timeseries_default_output_file = timeseries_csv_path
        end

        api = URBANopt::REopt::REoptLiteAPI.new(@nrel_developer_key, @localhost)
        adapter = URBANopt::REopt::ScenarioReportAdapter.new

        reopt_input = adapter.reopt_json_from_scenario_report(scenario_report, @scenario_reopt_default_assumptions_hash)
        
        reopt_output = api.reopt_request(reopt_input, @scenario_reopt_default_output_file)
        
        return adapter.update_scenario_report(scenario_report, reopt_output, @scenario_timeseries_default_output_file)
      end
      
      # Updates a set of FeatureReports based on an optional set of \REopt Lite optimization assumptions. 
      ##
      #
      # [*parameters:*]
      #
      # * +feature_reports+ - _Array_ -  An array of _URBANopt::Scenario::DefaultReports::FeatureReport_ objetcs which will each be used to create (and are subsquently updated by) a \REopt Lite opimization response.
      # * +reopt_assumptions_hashes+ - _Array_ - Optional. An array of \REopt Lite formatted hashes containing default parameters (i.e. utility rate, escalation rate) which will be updated by the ScenarioReport (i.e. location, roof availability). The number and order of the hashes should match the feature_reports array. 
      # * +reopt_output_files+ - _Array_ - Optional. A array of paths to files at which REpopt Lite responses will be saved. The number and order of the paths should match the feature_reports array.
      # * +timeseries_csv_path+ - _Array_ - Optional. A array of paths to files at which the new timeseries CSV for the FeatureReports will be saved. The number and order of the paths should match the feature_reports array.
      #
      # [*return:*] _Array_ Returns an array of updated _URBANopt::Scenario::DefaultReports::FeatureReport_ objects
      def run_feature_reports(feature_reports, reopt_assumptions_hashes=[], reopt_output_files=[],timeseries_csv_paths=[])
        
        if reopt_assumptions_hashes.length != 0
          @feature_reports_reopt_default_assumption_hashes = reopt_assumptions_hashes
        end
        
        if reopt_output_files.length != 0
          @feature_reports_reopt_default_output_files = reopt_output_files
        end
        
        if timeseries_csv_paths.length != 0
          @feature_reports_timeseries_default_output_files = timeseries_csv_paths
        end
        
        if @feature_reports_reopt_default_output_files.length == 0
          feature_reports.each do |fr|
            @feature_reports_reopt_default_output_files << File.join(fr.directory_name, "feature_report_#{fr.id}_reopt_run.json")
          end
        end

        if @feature_reports_timeseries_default_output_files.length == 0
          feature_reports.each do |fr|
            @feature_reports_timeseries_default_output_files << File.join(fr.directory_name, "feature_report_#{fr.id}_timeseries.csv")
          end
        end

        api = URBANopt::REopt::REoptLiteAPI.new(@nrel_developer_key, @localhost)
        feature_adapter = URBANopt::REopt::FeatureReportAdapter.new
        new_feature_reports = []
        feature_reports.each_with_index do |feature_report, idx|
          begin
            reopt_input = feature_adapter.reopt_json_from_feature_report(feature_report, @feature_reports_reopt_default_assumption_hashes[idx])
            if reopt_output_files[idx].nil?
              reopt_output_files[idx] = feature_report.directory_name
            end
            reopt_output = api.reopt_request(reopt_input, @feature_reports_reopt_default_output_files[idx])
            new_feature_report = feature_adapter.update_feature_report(feature_report, reopt_output, @feature_reports_timeseries_default_output_files[idx])
            new_feature_reports.push(new_feature_report)
          rescue
            @@logger.info("Could not optimize Feature Report #{feature_report.name} #{feature_report.id}")
          end
        end

        return new_feature_reports
      end

      # Updates a ScenarioReport based on an optional set of \REopt Lite optimization assumptions. 
      ##
      #
      # [*parameters:*]
      #
      # * +scenario_report+ - _Array_ -  A _URBANopt::Scenario::DefaultReports::ScenarioReport_ which will each be used to create (and is subsquently updated by) \REopt Lite opimization responses for each of its FeatureReports.
      # * +reopt_assumptions_hashes+ - _Array_ - Optional. An array of \REopt Lite formatted hashes containing default parameters (i.e. utility rate, escalation rate) which will be updated by the ScenarioReport (i.e. location, roof availability). The number and order of the hashes should match the array in ScenarioReport.feature_reports. 
      # * +reopt_output_files+ - _Array_ - Optional. An array of paths to files at which REpopt Lite responses will be saved. The number and order of the paths should match the array in ScenarioReport.feature_reports.
      # * +timeseries_csv_path+ - _Array_ - Optional. An array of paths to files at which the new timeseries CSV for the FeatureReports will be saved. The number and order of the paths should match the array in ScenarioReport.feature_reports.
      #
      # [*return:*] _URBANopt::Scenario::DefaultReports::ScenarioReport_ - Returns an updated ScenarioReport
      def run_scenario_report_features(scenario_report, reopt_assumptions_hashes=[], reopt_output_files=[],feature_report_timeseries_csv_paths=[], scenario_report_timeseries_csv_path=nil)
        if !scenario_report_timeseries_csv_path.nil?
          @scenario_timeseries_default_output_file = scenario_report_timeseries_csv_path
        end
        
        new_feature_reports = self.run_feature_reports(scenario_report.feature_reports, reopt_assumptions_hashes, reopt_output_files, feature_report_timeseries_csv_paths ) 

        new_scenario_report = URBANopt::Scenario::DefaultReports::ScenarioReport.new
        new_scenario_report.id = scenario_report.id
        new_scenario_report.name = scenario_report.name
        new_scenario_report.directory_name = scenario_report.directory_name
        
        if @scenario_timeseries_default_output_file.nil?
          feature_ids = scenario_report.feature_reports.map { |x|  x.id }
          @scenario_timeseries_default_output_file = scenario_report.timeseries_csv.path.sub! '.csv',"_updated_features#{feature_ids.join('_')}.csv"
        end
        
        timeseries_hash = {:path => @scenario_timeseries_default_output_file, :column_names => scenario_report.timeseries_csv.column_names }
        new_scenario_report.timeseries_csv = URBANopt::Scenario::DefaultReports::TimeseriesCSV.new(timeseries_hash)

        new_feature_reports.each do |feature_report|
          new_scenario_report.add_feature_report(feature_report)
        end
        
        new_scenario_report.timeseries_csv.save_data(@scenario_timeseries_default_output_file)
        
        return new_scenario_report
      end
    end
  end
end