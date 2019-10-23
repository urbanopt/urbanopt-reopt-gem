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
require 'urbanopt/reopt'
require 'csv'
require 'pry'

module URBANopt
  module REopt
    class REoptRunner
      ##
      # REoptRunner updates a ScenarioReport or FeatureReport based on REopt Lite optimization response.
      ##
      # [parameters:]
      # +use_localhost+ - _Bool_ - If this is true, requests will be sent to a version of the REopt Lite API running on localhost. Default is false, such that the production version of REopt Lite is accessed. 
      # +nreldeveloperkey+ - _String_ - API used to access the REopt Lite APi. Required only if localhost is false. Obtain from https://developer.nrel.gov/signup/
      ##
      def initialize(developernrelgovkey=nil, localhost=false)
        @developernrelgovkey = developernrelgovkey
        @localhost = localhost
        @reopt_base_post = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {},:Wind => {:max_kw => 0}}}}
      end

      ##
      # Updates a FeatureReport based on an optional set of REopt Lite optimization assumptions. 
      ##
      # [parameters:]
      # +feature_report+ - _FeatureReport_ -  FeatureReport which will be used in creating and then updated by a REopt Lite opimization response.
      # +reopt_assumptions_hash+ - _Hash_ - Optional. A REopt Lite formatted hash containing default parameters (i.e. utility rate, escalation rate) which will be updated by the FeatureReport (i.e. location, roof availability)
      # +reopt_output_file+ - _String_ - Optional. Path to a file at which REpopt Lite responses will be saved. 
      # +timeseries_csv_path+ - _String_ - Optional. Path to a file at which the new timeseries CSV for the FeatureReport will be saved. 
      # [return:] _FeatureReport_ Returns an updated FeatureReport
      ##
      def run_feature_report(feature_report, reopt_assumptions_hash=nil, reopt_output_file=nil,timeseries_csv_path=nil)
        api = URBANopt::REopt::REoptLiteAPI.new(@developernrelgovkey, @localhost)
        adapter = URBANopt::REopt::FeatureReportAdapter.new

        reopt_input = adapter.reopt_json_from_feature_report(feature_report, reopt_assumptions_hash)
        if reopt_output_file.nil?
          reopt_output_file = feature_report.directory_name
        end
        reopt_output = api.reopt_request(reopt_input, reopt_output_file)
        return adapter.update_feature_report(feature_report, reopt_output,timeseries_csv_path)
      end

##
      # Updates a ScenarioReport based on an optional set of REopt Lite optimization assumptions. 
      ##
      # [parameters:]
      # +feature_report+ - _ScenarioReport_ -  ScenarioReport which will be used in creating and then updated by a REopt Lite opimization response.
      # +reopt_assumptions_hash+ - _Hash_ - Optional. A REopt Lite formatted hash containing default parameters (i.e. utility rate, escalation rate) which will be updated by the ScenarioReport (i.e. location, roof availability)
      # +reopt_output_file+ - _String_ - Optional. Path to a file at which REpopt Lite responses will be saved. 
      # +timeseries_csv_path+ - _String_ - Optional. Path to a file at which the new timeseries CSV for the ScenarioReport will be saved.
      # [return:] _ScenarioReport_ Returns an updated ScenarioReport
      def run_scenario_report(scenario_report, reopt_assumptions_hash=nil, reopt_output_file=nil,timeseries_csv_path=nil)
        api = URBANopt::REopt::REoptLiteAPI.new(@developernrelgovkey, @localhost)
        adapter = URBANopt::REopt::ScenarioReportAdapter.new

        reopt_input = adapter.reopt_json_from_scenario_report(scenario_report, reopt_assumptions_hash)
        if reopt_output_file.nil?
          reopt_output_file = scenario_report.directory_name
        end
        reopt_output = api.reopt_request(reopt_input, reopt_output_file)

        return adapter.update_scenario_report(scenario_report, reopt_output, timeseries_csv_path)
      end
      
      # Updates a set of FeatureReports based on an optional set of REopt Lite optimization assumptions. 
      ##
      # [parameters:]
      # +feature_reports+ - _Array_ -  An array of FeatureReports which will each be used to create (and are subsquently updated by) a REopt Lite opimization response.
      # +reopt_assumptions_hashes+ - _Array_ - Optional. An array of REopt Lite formatted hashes containing default parameters (i.e. utility rate, escalation rate) which will be updated by the ScenarioReport (i.e. location, roof availability). The number and order of the hashes should match the feature_reports array. 
      # +reopt_output_files+ - _Array_ - Optional. A array of paths to files at which REpopt Lite responses will be saved. The number and order of the paths should match the feature_reports array.
      # +timeseries_csv_path+ - _Array_ - Optional. A array of paths to files at which the new timeseries CSV for the FeatureReports will be saved. The number and order of the paths should match the feature_reports array.
      # [return:] _Array_ Returns an array of updated FeatureReports
      def run_feature_reports(feature_reports, reopt_assumptions_hashes=[], reopt_output_files=[],timeseries_csv_paths=[])
        if reopt_assumptions_hashes.nil?
          reopt_assumptions_hashes = []
        end
        
        if reopt_output_files.nil?
          reopt_output_files = []
        end
        
        if timeseries_csv_paths.nil?
          timeseries_csv_paths = []
        end

        api = URBANopt::REopt::REoptLiteAPI.new(@developernrelgovkey, @localhost)
        feature_adapter = URBANopt::REopt::FeatureReportAdapter.new
        new_feature_reports = []
        feature_reports.each_with_index do |reopt_input, idx|
          begin
            reopt_input = adapter.reopt_json_from_feature_report(feature_report, reopt_assumptions_hashes[idx])
            if reopt_output_files[idx].nil?
              reopt_output_files[idx] = feature_report.directory_name
            end
            reopt_output = api.reopt_request(reopt_input, reopt_output_files[idx])
            new_feature_report = feature_adapter.update_feature_report(scenario_report.feature_reports[idx], reopt_output,timeseries_csv_paths[idx])
            new_feature_reports.push(new_feature_report)
          rescue
            p "Could not optimize Feature Report #{scenario_report.feature_reports[idx].name} #{scenario_report.feature_reports[idx].id}"
          end
        end

        return new_feature_reports
      end

      # Updates a ScenarioReport based on an optional set of REopt Lite optimization assumptions. 
      ##
      # [parameters:]
      # +feature_reports+ - _Array_ -  A ScenarioReport which will each be used to create (and is subsquently updated by) a REopt Lite opimization response.
      # +reopt_assumptions_hashes+ - _Array_ - Optional. An array of REopt Lite formatted hashes containing default parameters (i.e. utility rate, escalation rate) which will be updated by the ScenarioReport (i.e. location, roof availability). The number and order of the hashes should match the array in ScenarioReport.feature_reports. 
      # +reopt_output_files+ - _Array_ - Optional. An array of paths to files at which REpopt Lite responses will be saved. The number and order of the paths should match the array in ScenarioReport.feature_reports.
      # +timeseries_csv_path+ - _Array_ - Optional. An array of paths to files at which the new timeseries CSV for the FeatureReports will be saved. The number and order of the paths should match the array in ScenarioReport.feature_reports.
      # [return:] _Array_ Returns an updated ScenarioReport
      def run_scenario_report_features(scenario_report, reopt_assumptions_hashes=[], reopt_output_files=[],timeseries_csv_paths=[])
        if reopt_assumptions_hashes.nil?
          reopt_assumptions_hashes = []
        end
        
        if reopt_output_files.nil?
          reopt_output_files = []
        end
        
        if timeseries_csv_paths.nil?
          timeseries_csv_paths = []
        end
        api = URBANopt::REopt::REoptLiteAPI.new(@developernrelgovkey, @localhost)
        scenario_adapter = URBANopt::REopt::ScenarioReportAdapter.new
        feature_adapter = URBANopt::REopt::FeatureReportAdapter.new

        reopt_inputs  = scenario_adapter.reopt_jsons_from_scenario_feature_reports(scenario_report, reopt_assumptions_hashes)

        new_feature_reports = []
        reopt_inputs.each_with_index do |reopt_input, idx|
          begin
            if reopt_output_files[idx].nil?
              reopt_output_files[idx] = scenario_report.directory_name
            end
            reopt_output = api.reopt_request(reopt_input, reopt_output_files[idx])
            new_feature_report = feature_adapter.update_feature_report(scenario_report.feature_reports[idx], reopt_output)
            new_feature_reports.push(new_feature_report)
          rescue
            p "Could not optimize Feature Report #{scenario_report.feature_reports[idx].name} #{scenario_report.feature_reports[idx].id}"
          end
        end

        return scenario_adapter.update_scenario_report_from_feature_reports(scenario_report, new_feature_reports,timeseries_csv_paths)
      end
    end
  end
end