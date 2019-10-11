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

      def initialize
        @reopt_base_post = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {},:Wind => {:max_kw => 0}}}}
      end

      def run_feature_report(feature_report, reopt_base = nil)
        if !reopt_base.nil?
          reopt_base = @reopt_base_post
        end

        api = URBANopt::REopt::REoptLiteAPI.new
        adapter = URBANopt::REopt::FeatureReportAdapter.new

        reopt_input = adapter.from_feature_report(feature_report, reopt_base)
        reopt_output = api.reopt_request(reopt_input, feature_report.directory_name)
        return adapter.update_feature_report(feature_report, reopt_output)
      end

      def run_scenario_report(scenario_report, reopt_base = nil)
        if !reopt_base.nil?
          reopt_base = @reopt_base_post
        end
        api = URBANopt::REopt::REoptLiteAPI.new
        adapter = URBANopt::REopt::ScenarioReportAdapter.new

        reopt_input = adapter.reopt_json_from_scenario_report(scenario_report, reopt_base)

        reopt_output = api.reopt_request(reopt_input, scenario_report.directory_name)

        return adapter.update_scenario_report_from_scenario_report(scenario_report, reopt_output)
      end

      def run_scenario_report_features(scenario_report, reopt_base = nil)
        if !reopt_base.nil?
          reopt_base = @reopt_base_post
        end

        api = URBANopt::REopt::REoptLiteAPI.new
        scenario_adapter = URBANopt::REopt::ScenarioReportAdapter.new
        feature_adapter = URBANopt::REopt::FeatureReportAdapter.new

        reopt_inputs  = scenario_adapter.feature_reports_from_scenario_report(scenario_report, reopt_base)

        new_feature_reports = []
        reopt_inputs.each_with_index do |reopt_input, idx|
          reopt_output = api.reopt_request(reopt_input, scenario_report.feature_reports[idx].directory_name)
          new_feature_report = feature_adapter.update_feature_report(scenario_report.feature_reports[idx], reopt_output)
          new_feature_reports.push(new_feature_report)
        end

        return scenario_adapter.update_scenario_report_from_feature_reports(scenario_report, new_feature_reports)
      end
    end
  end
end