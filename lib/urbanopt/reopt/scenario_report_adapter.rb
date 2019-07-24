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

require "urbanopt/scenario/default_reports"
require 'csv'
require 'pry'

module URBANopt
  module REopt
    class ScenarioReportAdapter
    
      def initialize

      end
      
      def from_scenario_report(scenario_report, run_cumulative=true)
        
        # are there inputs for reopt from these?
        # "program": 
        # "construction_costs":
        # "reporting_periods": 
          
        binding.pry
        if run_cumulative
          scenario_report.location[:latitude] = 40
          scenario_report.location[:longitude] = -100
          scenario_report.timeseries_csv.path = 'spec/files/default_feature_reports.csv'
          scenario_report.timeseries_csv.column_names = ['Electricity:Facility','ElectricityProduced:Facility','Gas:Facility','DistrictCooling:Facility','DistrictHeating:Facility','District Cooling Chilled Water Rate','District Cooling Mass Flow Rate','District Cooling Inlet Temperature','District Cooling Outlet Temperature','District Heating Hot Water Rate','District Heating Mass Flow Rate','District Heating Inlet Temperature','District Heating Outlet Temperature']


          required_attrs = [scenario_report.id, scenario_report.name, scenario_report.directory_name, scenario_report.number_of_not_started_simulations, scenario_report.number_of_started_simulations, scenario_report.number_of_complete_simulations, scenario_report.number_of_failed_simulations].map {|x| if x.nil? then 'nil' else x end}
          description = "#{required_attrs.join(" ")}"

          reopt_inputs = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {}}}}
          
          requireds_names = ['latitude','longitude']
          requireds = [scenario_report.location[:latitude],scenario_report.location[:longitude]]

          if requireds.include? nil or requireds.include? 0
            requireds.each_with_index do |i,x|
               if [nil,0].include? x
                n = requireds_names[i]
                raise "Missing value for #{n} - this is a required input"
               end
            end
          end
          
          reopt_inputs[:Scenario][:description] = description
          reopt_inputs[:Scenario][:Site][:latitude] = scenario_report.location[:latitude]
          reopt_inputs[:Scenario][:Site][:longitude] = scenario_report.location[:longitude]
          
          if !scenario_report.program.roof_area.nil?
            reopt_inputs[:Scenario][:Site][:roof_squarefeet] = scenario_report.program.roof_area[:available_roof_area]
          end
          
          if !scenario_report.program.site_area.nil?
            reopt_inputs[:Scenario][:Site][:land_acres] = scenario_report.program.site_area * 1.0/43560 #acres/sqft
          end
        
          begin 
            col_num = scenario_report.timeseries_csv.column_names.index("Electricity:Facility")
            t = CSV.read(scenario_report.timeseries_csv.path,headers: true,converters: :numeric)
            energy_timeseries_kwh = t.by_col[col_num]
            if scenario_report.timesteps_per_hour > 1
               energy_timeseries_kwh = energy_timeseries_kwh.each_slice(scenario_report.timesteps_per_hour).to_a.map {|x| x.inject(0, :+)/(x.lengtsh.to_f)}
            end
            reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = energy_timeseries_kwh
          rescue
            raise "Could not parse the annual electric load from the timeseries csv - #{scenario_report.timeseries_csv.path}"
          end

          reopt_inputs[:Scenario][:Site][:ElectricTariff][:urdb_label] = '594976725457a37b1175d089'
          return reopt_inputs
        else
          result = []
          adapter = URBANopt::REopt::FeatureReportAdapter.new
          scenario_report.feature_reports.each {|fr|
            feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(fr)
            reopt_input = adapter.from_feature_report(feature_report)
            result.push(reopt_input) 
          }
          return result
        end
      end
      
      def to_scenario_report(reopt_output)
        
        return {}
      end

    end
  end
end