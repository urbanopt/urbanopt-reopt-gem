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
    class FeatureReportAdapter
    
      def initialize

      end
      
      def from_feature_report(feature_report)
        required_attrs = [feature_report.id, feature_report.name, feature_report.feature_type, feature_report.directory_name, feature_report.simulation_status]
        required_attrs = [1,2,3,4,5]
        required_attrs = required_attrs.map {|x| if x.nil? then 'nil' else x end}
        description = "#{required_attrs.join(" ")}"
        p description

        return {:Scenario => 
                  {:description => description, :Site => 
                    {:latitude => 40, :longitude => -110,
                      :ElectricTariff => {:urdb_label => '594976725457a37b1175d089'}, 
                      :LoadProfile => {:doe_reference_name => 'Hospital', :annual_kwh => 1000000 }
                    }
                  }
                }

        reopt_inputs = {:Scenario => {:Site => {:ElectricTariff => {}, :LoadProfile => {}}}}
        
        requireds_names = ['latitude','longitude']
        requireds = [feature_report.location[:latitude],feature_report.location[:longitude]]

        if requireds.include? nil or requireds.include? 0
          requireds.each_with_index do |i,x|
             if [nil,0].include? x
              n = requireds_names[i]
              raise "Missing value for #{n} - this is a required input"
             end
          end
        end

        reopt_inputs[:Scenario][:description] = description
        reopt_inputs[:Scenario][:Site][:latitude] = feature_report.location[:latitude]
        reopt_inputs[:Scenario][:Site][:longitude] = feature_report.location[:longitude]
        reopt_inputs[:Scenario][:Site][:roof_squarefeet] = feature_report.program.roof_area[:available_roof_area]
        reopt_inputs[:Scenario][:Site][:land_acres] = feature_report.program.site_area
      


        # CSV.read(scenario_report[:timeseries_csv][:path],headers: true)
        # table.by_col[0]

        # scenario_report[:timesteps_per_hour]

        

        

        # reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = 



        # = scenario_report[:program][:orientation]
        # = scenario_report[:program][:aspect_ratio]
        
        # = scenario_report[:reporting_periods][:electricity]
          # return a reopt_input
        return reopt_inputs
      end
      
      def to_feature_report(reopt_output)
        feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new({})
        
        requireds = reopt_output['inputs']['Scenario']['description'].split(' ')
        
        #Required
        
        feature_report.id = eval requireds[0]
        
        feature_report.name =  eval requireds[1]
        feature_report.directory_name = eval  requireds[2]
        feature_report.feature_type = eval requireds[3]
        feature_report.simulation_status = eval requireds[4]
        
        feature_report.timesteps_per_hour =  reopt_output['inputs']['Scenario']['time_steps_per_hour']
        
        #Non-required
        
        feature_report.location[:latitude] =   reopt_output['inputs']['Scenario']['Site']['latitude']
        feature_report.location[:longitude] =   reopt_output['inputs']['Scenario']['Site']['longitude']
        feature_report.location[:surface_elevation] = nil  
        feature_report.location[:weather_filename] = nil
        
        feature_report.program.site_area = nil
        feature_report.program.floor_area = nil
        feature_report.program.conditioned_area = nil 
        feature_report.program.unconditioned_area = nil
        feature_report.program.footprint_area = nil
        feature_report.program.maximum_roof_height = nil
        feature_report.program.maximum_number_of_stories = nil
        feature_report.program.maximum_number_of_stories_above_ground = nil
        feature_report.program.parking_area = nil
        feature_report.program.number_of_parking_spaces = nil
        feature_report.program.number_of_parking_spaces_charging = nil
        feature_report.program.parking_footprint_area = nil
        feature_report.program.maximum_parking_height = nil
        feature_report.program.maximum_number_of_parking_stories = nil
        feature_report.program.maximum_number_of_parking_stories_above_ground = nil
        feature_report.program.number_of_residential_units = nil

        feature_report.program.building_types[0][:building_type] =  nil
        feature_report.program.building_types[0][:maximum_occupancy] =  nil
        feature_report.program.building_types[0][:floor_area] =  nil

        feature_report.program.window_area[:north_window_area] = nil
        feature_report.program.window_area[:south_window_area] = nil
        feature_report.program.window_area[:east_window_area] = nil
        feature_report.program.window_area[:west_window_area] = nil
        feature_report.program.window_area[:total_window_area] = nil

        feature_report.program.wall_area[:north_window_area] = nil
        feature_report.program.wall_area[:south_window_area] = nil
        feature_report.program.wall_area[:east_window_area] = nil
        feature_report.program.wall_area[:west_window_area] = nil
        feature_report.program.wall_area[:total_window_area] = nil

        feature_report.program.roof_area[:equipment_roof_area] = nil
        feature_report.program.roof_area[:photovoltaic_roof_area] = nil
        feature_report.program.roof_area[:available_roof_area] = nil
        feature_report.program.roof_area[:total_roof_area] = nil

        feature_report.program.orientation = nil
        feature_report.program.aspect_ratio = nil

        feature_report.timeseries_csv.path =  nil
        feature_report.timeseries_csv.first_report_datetime =  nil
        feature_report.timeseries_csv.column_names =  nil

        feature_report.design_parameters = {}
        feature_report.design_parameters[:district_cooling_chilled_water_rate] =  nil
        feature_report.design_parameters[:district_cooling_mass_flow_rate] =  nil
        feature_report.design_parameters[:district_cooling_inlet_temperature] =  nil
        feature_report.design_parameters[:district_cooling_outlet_temperature] =  nil
        feature_report.design_parameters[:district_heating_hot_water_rate] =  nil
        feature_report.design_parameters[:district_heating_mass_flow_rate] =  nil
        feature_report.design_parameters[:district_heating_inlet_temperature] =  nil
        feature_report.design_parameters[:district_heating_outlet_temperature] =  nil

        feature_report.construction_costs = [] 
        feature_report.reporting_periods = []
        
    
        return feature_report
      end

    end
  end
end