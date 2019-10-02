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
        #
        scenario_report.directory_name = "spec/files/"

        if run_cumulative

          scenario_report.timeseries_csv.path = 'spec/files/default_feature_reports.csv'
          scenario_report.timeseries_csv.column_names = ['Electricity:Facility','ElectricityProduced:Facility','Gas:Facility','DistrictCooling:Facility','DistrictHeating:Facility','District Cooling Chilled Water Rate','District Cooling Mass Flow Rate','District Cooling Inlet Temperature','District Cooling Outlet Temperature','District Heating Hot Water Rate','District Heating Mass Flow Rate','District Heating Inlet Temperature','District Heating Outlet Temperature']

          required_attrs = [scenario_report.id, scenario_report.name, 'scenario'].map {|x| if x.nil? then 'nil' else x end}
          description = "#{required_attrs.join(" ")}"

          reopt_inputs = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {}}}}

          if scenario_report.location.latitude.nil? or scenario_report.location.longitude.nil? or scenario_report.location.latitude == 0 or scenario_report.location.longitude == 0
            if !scenario_report.feature_reports.nil? and scenario_report.feature_reports != []
              lats = []
              longs = []
              scenario_report.feature_reports.each do |x|
                if ![nil,0].include? x[:location][:latitude] and ![nil,0].include? x[:location][:longitude]
                  lats.push(x[:location][:latitude])
                  longs.push(x[:location][:longitude])
                end
              end

              if lats.size > 0 and longs.size > 0
                scenario_report.location.latitude = lats.reduce(:+) / lats.size.to_f
                scenario_report.location.longitude = longs.reduce(:+) / longs.size.to_f
              end
            end
          end

          requireds_names = ['latitude','longitude']
          requireds = [scenario_report.location.latitude,scenario_report.location.longitude]

          if requireds.include? nil or requireds.include? 0
            requireds.each_with_index do |i,x|
               if [nil,0].include? x
                n = requireds_names[i]
                raise "Missing value for #{n} - this is a required input"
               end
            end
          end

          reopt_inputs[:Scenario][:description] = description

          reopt_inputs[:Scenario][:Site][:latitude] = scenario_report.location.latitude
          reopt_inputs[:Scenario][:Site][:longitude] = scenario_report.location.longitude

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
            if scenario_report.timesteps_per_hour or 1 > 1
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
      
      def update_scenario_report(scenario_report, reopt_output)

        requireds = reopt_output['inputs']['Scenario']['description'].split(' ')

        #Required
        if (scenario_report.id != requireds[0]) or (scenario_report.name !=  requireds[1]) or ('scenario' != requireds[2])
           p "Warning: Not the same feature used to call REopt"
        end

        scenario_report.timesteps_per_hour =  reopt_output['inputs']['Scenario']['time_steps_per_hour']

        generation_timeseries_kwh = Matrix[[0]*8760]
        unless reopt_output['outputs']['Scenario']['Site']['PV'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['PV']['size_kw'] or 0) > 0
            generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['PV']['year_one_power_production_series_kw'] ]
          end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Storage'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Storage']['size_kw'] or 0) > 0
            generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw'] ]
          end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Wind'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Wind']['size_kw'] or 0) > 0
            generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'] ]
          end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Generator'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Generator']['size_kw'] or 0) > 0
            generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'] ]
          end
        end


        $generation_timeseries_kwh = generation_timeseries_kwh.to_a[0]
        $generation_timeseries_kwh_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Facility")
        $utility_to_load = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_load_series_kw']
        $utility_to_load_col = scenario_report.timeseries_csv.column_names.index("Electricity:Facility")

        def modrow(x,i)
          x[$generation_timeseries_kwh_col] = $generation_timeseries_kwh[i]
          x[$utility_to_load_col] = $utility_to_load[i]
          return x
        end

        old_data = CSV.open(scenario_report.timeseries_csv.path).read()
        mod_data = old_data.map.with_index {|x,i|
          if i > 0 then
            modrow(x,i)
          else
            x
          end
        }
        scenario_report.timeseries_csv.path = scenario_report.timeseries_csv.path.sub! '.csv','_copy.csv'
        File.write(scenario_report.timeseries_csv.path, mod_data.map(&:to_csv).join)

        #Non-required
        scenario_report.location.latitude =   reopt_output['inputs']['Scenario']['Site']['latitude']
        scenario_report.location.longitude =   reopt_output['inputs']['Scenario']['Site']['longitude']

        return scenario_report
      end
    end
  end
end