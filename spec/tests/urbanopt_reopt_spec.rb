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

RSpec.describe URBANopt::REopt do
  it 'has a version number' do
    expect(URBANopt::REopt::VERSION).not_to be nil
  end

  it 'has a measures directory' do
    instance = URBANopt::REopt::Extension.new
    expect(File.exist?(instance.measures_dir)).to be true
  end

  it 'can connect to reopt lite' do
    api = URBANopt::REopt::REoptLiteAPI.new
    dummy_data = {:Scenario => {:Site => {:latitude => 40, :longitude => -110, :Wind => {:max_kw => 0}, :ElectricTariff => {:urdb_label => '594976725457a37b1175d089'}, :LoadProfile => {:doe_reference_name => 'Hospital', :annual_kwh => 1000000 }}}}
    ok = api.check_connection(dummy_data)
    expect(ok).to be true
  end

  it 'can process a feature report' do
    feature_reports_path = File.join(File.dirname(__FILE__), '../files/default_feature_report.json')

    expect(File.exists?(feature_reports_path)).to be true

    feature_reports_json = nil
    File.open(feature_reports_path, 'r') do |file|
      feature_reports_json = JSON.parse(file.read, symbolize_names: true)
    end


    feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(feature_reports_json)

    api = URBANopt::REopt::REoptLiteAPI.new
    adapter = URBANopt::REopt::FeatureReportAdapter.new

    reopt_input = adapter.from_feature_report(feature_report)
    reopt_output = api.reopt_request(reopt_input,feature_report.directory_name)

    adapter.update_feature_report(feature_report,reopt_output)
  end

  it 'can process a scenario report' do
    scenario_reports_path = File.join(File.dirname(__FILE__), '../files/default_scenario_report.json')

    expect(File.exists?(scenario_reports_path)).to be true

    scenario_reports_json = nil
    File.open(scenario_reports_path, 'r') do |file|
      scenario_reports_json = JSON.parse(file.read, symbolize_names: true)
    end

    scenario_report = URBANopt::Scenario::DefaultReports::ScenarioReport.new(scenario_reports_json[:scenario_report])
    scenario_reports_json[:feature_reports].each do |fr|
      feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(fr)
      scenario_report.feature_reports << feature_report
    end

    api = URBANopt::REopt::REoptLiteAPI.new
    adapter = URBANopt::REopt::ScenarioReportAdapter.new

    reopt_input = adapter.reopt_json_from_scenario_report(scenario_report)

    reopt_output = api.reopt_request(reopt_input, scenario_report.directory_name)

    adapter.update_scenario_report_from_scenario_report(scenario_report, reopt_output)

  end

  it 'can process all feature reports in a scenario report individually' do
    scenario_reports_path = File.join(File.dirname(__FILE__), '../files/default_scenario_report.json')

    expect(File.exists?(scenario_reports_path)).to be true

    scenario_reports_json = nil
    File.open(scenario_reports_path, 'r') do |file|
      scenario_reports_json = JSON.parse(file.read, symbolize_names: true)
    end

    scenario_report = URBANopt::Scenario::DefaultReports::ScenarioReport.new(scenario_reports_json[:scenario_report])
    scenario_reports_json[:feature_reports].each do |fr|
      feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(fr)
      scenario_report.feature_reports << feature_report
    end

    api = URBANopt::REopt::REoptLiteAPI.new
    scenario_adapter = URBANopt::REopt::ScenarioReportAdapter.new
    feature_adapter = URBANopt::REopt::FeatureReportAdapter.new

    reopt_inputs  = scenario_adapter.feature_reports_from_scenario_report(scenario_report)

    new_feature_reports = []
    reopt_inputs.each_with_index do |reopt_input, idx|
      reopt_output = api.reopt_request(reopt_input, scenario_report.directory_name)
      new_feature_report = feature_adapter.update_feature_report(scenario_report.feature_reports[idx], reopt_output)
      new_feature_reports.push(new_feature_report)
    end

    scenario_adapter.update_scenario_report_from_feature_reports(scenario_report, new_feature_reports)

  end
end
