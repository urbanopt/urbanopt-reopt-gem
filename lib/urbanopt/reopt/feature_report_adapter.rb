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
require 'matrix'
require 'pry'


module URBANopt
  module REopt
    class FeatureReportAdapter

      def initialize
      end

      def from_feature_report(feature_report)
        name = feature_report.name.sub! ' ',''
        description = "feature_report_#{name}_#{feature_report.id}"
        reopt_inputs = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {},:Wind => {:max_kw => 0}}}}

        requireds_names = ['latitude','longitude']

        requireds = [feature_report.location.latitude,feature_report.location.longitude]

        if requireds.include? nil or requireds.include? 0
          requireds.each_with_index do |i,x|
             if [nil,0].include? x
              n = requireds_names[i]
              raise "Missing value for #{n} - this is a required input"
             end
          end
        end

        reopt_inputs[:Scenario][:description] = description

        reopt_inputs[:Scenario][:Site][:latitude] = feature_report.location.latitude
        reopt_inputs[:Scenario][:Site][:longitude] = feature_report.location.longitude

        unless feature_report.program.roof_area.nil?
          reopt_inputs[:Scenario][:Site][:roof_squarefeet] = feature_report.program.roof_area[:available_roof_area]
        end

        unless feature_report.program.site_area.nil?
          reopt_inputs[:Scenario][:Site][:land_acres] = feature_report.program.site_area * 1.0/43560 #acres/sqft
        end

        begin
          col_num = feature_report.timeseries_csv.column_names.index("Electricity:Facility")
          t = CSV.read(feature_report.timeseries_csv.path,headers: true,converters: :numeric)
          energy_timeseries_kwh = t.by_col[col_num]
          if feature_report.timesteps_per_hour > 1
             energy_timeseries_kwh = energy_timeseries_kwh.each_slice(feature_report.timesteps_per_hour).to_a.map {|x| x.inject(0, :+)/(x.length.to_f)}
          end
          reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = energy_timeseries_kwh
        rescue
          raise "Could not parse the annual electric load from the timeseries csv - #{feature_report.timeseries_csv.path}"
        end

        reopt_inputs[:Scenario][:Site][:ElectricTariff][:urdb_label] = '594976725457a37b1175d089'

        return reopt_inputs
      end

      def update_feature_report(feature_report, reopt_output)

        #Required

        feature_report.timesteps_per_hour =  reopt_output['inputs']['Scenario']['time_steps_per_hour']

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
        $generation_timeseries_kwh_col = feature_report.timeseries_csv.column_names.index("ElectricityProduced:Facility")
        $utility_to_load = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_load_series_kw']
        $utility_to_load_col = feature_report.timeseries_csv.column_names.index("Electricity:Facility")

        def modrow(x,i)
          x[$generation_timeseries_kwh_col] = $generation_timeseries_kwh[i]
          x[$utility_to_load_col] = $utility_to_load[i]
          return x
        end
        
        old_data = CSV.open(feature_report.timeseries_csv.path).read()
        mod_data = old_data.map.with_index {|x,i|
          if i > 0 then
            modrow(x,i)
          else
            x
          end
        }
        feature_report.timeseries_csv.path = feature_report.timeseries_csv.path.sub! '.csv','_copy.csv'
        File.write(feature_report.timeseries_csv.path, mod_data.map(&:to_csv).join)

        #Non-required
        feature_report.location.latitude =   reopt_output['inputs']['Scenario']['Site']['latitude']
        feature_report.location.longitude =   reopt_output['inputs']['Scenario']['Site']['longitude']
        # feature_report.location[:surface_elevation] = nil
        # feature_report.location[:weather_filename] = nil

        # feature_report.program.site_area = nil
        # feature_report.program.floor_area = nil
        # feature_report.program.conditioned_area = nil
        # feature_report.program.unconditioned_area = nil
        # feature_report.program.footprint_area = nil
        # feature_report.program.maximum_roof_height = nil
        # feature_report.program.maximum_number_of_stories = nil
        # feature_report.program.maximum_number_of_stories_above_ground = nil
        # feature_report.program.parking_area = nil
        # feature_report.program.number_of_parking_spaces = nil
        # feature_report.program.number_of_parking_spaces_charging = nil
        # feature_report.program.parking_footprint_area = nil
        # feature_report.program.maximum_parking_height = nil
        # feature_report.program.maximum_number_of_parking_stories = nil
        # feature_report.program.maximum_number_of_parking_stories_above_ground = nil
        # feature_report.program.number_of_residential_units = nil

        # feature_report.program.building_types = [{}]
        # feature_report.program.building_types[0][:building_type] =  nil
        # feature_report.program.building_types[0][:maximum_occupancy] =  nil
        # feature_report.program.building_types[0][:floor_area] =  nil

        # feature_report.program.window_area[:north_window_area] = nil
        # feature_report.program.window_area[:south_window_area] = nil
        # feature_report.program.window_area[:east_window_area] = nil
        # feature_report.program.window_area[:west_window_area] = nil
        # feature_report.program.window_area[:total_window_area] = nil

        # feature_report.program.wall_area[:north_window_area] = nil
        # feature_report.program.wall_area[:south_window_area] = nil
        # feature_report.program.wall_area[:east_window_area] = nil
        # feature_report.program.wall_area[:west_window_area] = nil
        # feature_report.program.wall_area[:total_window_area] = nil

        # feature_report.program.roof_area[:equipment_roof_area] = nil
        # feature_report.program.roof_area[:photovoltaic_roof_area] = nil
        # feature_report.program.roof_area[:available_roof_area] = nil
        # feature_report.program.roof_area[:total_roof_area] = nil

        # feature_report.program.orientation = nil
        # feature_report.program.aspect_ratio = nil

        # feature_report.timeseries_csv.path =  nil
        # feature_report.timeseries_csv.first_report_datetime =  nil
        # feature_report.timeseries_csv.column_names =  nil

        # feature_report.design_parameters = {}
        # feature_report.design_parameters[:district_cooling_chilled_water_rate] =  nil
        # feature_report.design_parameters[:district_cooling_mass_flow_rate] =  nil
        # feature_report.design_parameters[:district_cooling_inlet_temperature] =  nil
        # feature_report.design_parameters[:district_cooling_outlet_temperature] =  nil
        # feature_report.design_parameters[:district_heating_hot_water_rate] =  nil
        # feature_report.design_parameters[:district_heating_mass_flow_rate] =  nil
        # feature_report.design_parameters[:district_heating_inlet_temperature] =  nil
        # feature_report.design_parameters[:district_heating_outlet_temperature] =  nil

        # feature_report.construction_costs = []
        # feature_report.reporting_periods = []


        return feature_report
      end

    end
  end
end