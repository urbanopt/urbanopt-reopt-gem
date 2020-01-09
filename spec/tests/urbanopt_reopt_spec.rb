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


require_relative '../spec_helper'
require_relative '../../developer_nrel_key'
require 'certified'

RSpec.describe URBANopt::REopt do
  it 'has a version number' do
    expect(URBANopt::REopt::VERSION).not_to be nil
  end

  it 'can connect to reopt lite' do
	api = URBANopt::REopt::REoptLiteAPI.new(DEVELOPER_NREL_KEY, false)
    dummy_data = {:Scenario => {:Site => {:latitude => 40, :longitude => -110, :Wind => {:max_kw => 0}, :ElectricTariff => {:urdb_label => '594976725457a37b1175d089'}, :LoadProfile => {:doe_reference_name => 'Hospital', :annual_kwh => 1000000 }}}}
    ok = api.check_connection(dummy_data)
    expect(ok).to be true
  end

  it 'can process a feature report' do
    feature_reports_path = File.join(File.dirname(__FILE__), '../run/example_scenario/1/010_default_feature_reports/default_feature_reports.json')

    expect(File.exists?(feature_reports_path)).to be true

    feature_reports_json = nil
    File.open(feature_reports_path, 'r') do |file|
      feature_reports_json = JSON.parse(file.read, symbolize_names: true)
    end

    feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(feature_reports_json)
    
    feature_report_dir = File.join(File.dirname(__FILE__), '../run/example_scenario/1')
    feature_report.directory_name = feature_report_dir
    feature_report.timeseries_csv.path = 'spec/run/example_scenario/1/010_default_feature_reports/default_feature_reports.csv'

    
    reopt_output_file = File.join(feature_report.directory_name, 'feature_report_reopt_run1.json')
    timeseries_output_file = File.join(feature_report.directory_name, 'feature_report_timeseries1.csv')
    reopt_assumptions_file = File.join(File.dirname(__FILE__), '../files/reopt_assumptions_basic.json')
    reopt_assumptions = nil
    File.open(reopt_assumptions_file, 'r') do |file|
      reopt_assumptions = JSON.parse(file.read, symbolize_names: true)
    end
    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(nil, nil, nil, DEVELOPER_NREL_KEY)
    
    feature_report = reopt_post_processor.run_feature_report(feature_report, reopt_assumptions, reopt_output_file,timeseries_output_file)
    feature_report = reopt_post_processor.run_feature_report(feature_report, nil, reopt_output_file,timeseries_output_file)
    feature_report = reopt_post_processor.run_feature_report(feature_report, reopt_assumptions, nil,timeseries_output_file)
    feature_report = reopt_post_processor.run_feature_report(feature_report, reopt_assumptions, reopt_output_file, nil)
    feature_report = reopt_post_processor.run_feature_report(feature_report)
  
  end

  it 'can process a scenario report' do
    scenario_report = URBANopt::Scenario::DefaultReports::ScenarioReport.new({:timeseries_csv => {:path => File.join(File.dirname(__FILE__), '../run/example_scenario/timeseries.csv') }})
    
    scenario_report_dir = File.join(File.dirname(__FILE__), '../run/example_scenario')
    scenario_report.directory_name = scenario_report_dir

    (1..2).each do |i|
      feature_reports_path = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}/010_default_feature_reports/default_feature_reports.json")

      expect(File.exists?(feature_reports_path)).to be true

      feature_reports_json = nil
      File.open(feature_reports_path, 'r') do |file|
        feature_reports_json = JSON.parse(file.read, symbolize_names: true)
      end

      feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(feature_reports_json)
      
      feature_report_dir = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}")
      feature_report.directory_name = feature_report_dir
      feature_report.timeseries_csv.path = "spec/run/example_scenario/#{i}/010_default_feature_reports/default_feature_reports.csv"
      scenario_report.add_feature_report(feature_report)
    end
    
    reopt_output_file = File.join(scenario_report.directory_name, "scenario_report_reopt_run.json")
    timeseries_output_file = File.join(scenario_report.directory_name, 'scenario_report_timeseries1.csv')
    reopt_assumptions_file = File.join(File.dirname(__FILE__), '../files/reopt_assumptions_basic.json')
    
    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(scenario_report,reopt_assumptions_file, nil, DEVELOPER_NREL_KEY)
    scenario_report = reopt_post_processor.run_scenario_report(scenario_report)
  
  end

  
  it 'can process a set of feature reports' do
    reopt_assumption_files = []
    reopt_assumption_jsons = []
    reopt_assumptions_file = File.join(File.dirname(__FILE__), '../files/reopt_assumptions_basic.json')
    reopt_assumptions = nil
    feature_reports = []
    reopt_output_files = []
    timeseries_output_files = []
      
    (1..2).each do |i|
      feature_reports_path = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}/010_default_feature_reports/default_feature_reports.json")

      expect(File.exists?(feature_reports_path)).to be true

      feature_reports_json = nil
      File.open(feature_reports_path, 'r') do |file|
        feature_reports_json = JSON.parse(file.read, symbolize_names: true)
      end

      feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(feature_reports_json)
      
      feature_report_dir = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}")
      feature_report.directory_name = feature_report_dir
      feature_report.timeseries_csv.path = "spec/run/example_scenario/#{i}/010_default_feature_reports/default_feature_reports.csv"
      
      reopt_assumption_files << reopt_assumptions_file
      #reopt_output_files << File.join(feature_report.directory_name, "feature_report#{feature_report.id}_reopt_run.json")
      #timeseries_output_files << File.join(feature_report.directory_name, "feature_report#{feature_report.id}_timeseries.csv")
      feature_reports << feature_report
    end

    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(nil, nil, reopt_assumption_files, DEVELOPER_NREL_KEY)
    processed_feature_reports = reopt_post_processor.run_feature_reports(feature_reports)
  end

  it 'can process all feature reports in a scenario report individually' do
    scenario_report = URBANopt::Scenario::DefaultReports::ScenarioReport.new({:timeseries_csv => {:path => File.join(File.dirname(__FILE__), '../run/example_scenario/timeseries.csv') }})
    
    scenario_report_dir = File.join(File.dirname(__FILE__), '../run/example_scenario')
    scenario_report.directory_name = scenario_report_dir

    reopt_assumption_jsons = []
    reopt_assumptions_file = File.join(File.dirname(__FILE__), '../files/reopt_assumptions_basic.json')
    reopt_assumptions = nil
    File.open(reopt_assumptions_file, 'r') do |file|
      reopt_assumptions = JSON.parse(file.read, symbolize_names: true)
    end
    reopt_assumption_files = []
    reopt_output_files = []
    scenario_report_timeseries_output_file = File.join(scenario_report.directory_name, "scenario_report#{scenario_report.id}_timeseries.csv")
    feature_report_timeseries_output_files = []

    (1..2).each do |i|

      feature_reports_path = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}/010_default_feature_reports/default_feature_reports.json")

      expect(File.exists?(feature_reports_path)).to be true

      feature_reports_json = nil
      File.open(feature_reports_path, 'r') do |file|
        feature_reports_json = JSON.parse(file.read, symbolize_names: true)
      end

      feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(feature_reports_json)
      feature_report_dir = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}")
      feature_report.directory_name = feature_report_dir
      feature_report.timeseries_csv.path = "spec/run/example_scenario/#{i}/010_default_feature_reports/default_feature_reports.csv"

      reopt_assumption_files << reopt_assumptions_file
      reopt_assumption_jsons << Marshal.load(Marshal.dump(reopt_assumptions))
      reopt_output_files << File.join(feature_report.directory_name, "feature_report#{feature_report.id}_reopt_run.json")
      feature_report_timeseries_output_files << File.join(feature_report.directory_name, "feature_report#{feature_report.id}_timeseries.csv")
      
      scenario_report.add_feature_report(feature_report)
    end
    
    reopt_output_file = File.join(scenario_report.directory_name, "scenario_report_reopt_run.json")
    timeseries_output_file = File.join(scenario_report.directory_name, 'scenario_report_timeseries1.csv')
    reopt_assumptions_file = File.join(File.dirname(__FILE__), '../files/reopt_assumptions_basic.json')
    
    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(scenario_report, reopt_assumptions_file, reopt_assumption_files, DEVELOPER_NREL_KEY)
    scenario_report = reopt_post_processor.run_scenario_report_features(scenario_report)
  end
end
