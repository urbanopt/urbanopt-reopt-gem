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
require "urbanopt/reopt/reopt_logger"

require 'csv'

module URBANopt  # :nodoc:
  module REopt  # :nodoc:
    class ScenarioReportAdapter
      ##
      # ScenarioReportAdapter can convert a ScenarioReport into a \REopt Lite posts or updates a ScenarioReport and its FeatureReports from \REopt Lite response(s)
      ##
      # [*parameters:*]
      def initialize
        # initialize @@logger
        @@logger ||= URBANopt::REopt.reopt_logger
      end
      
      ##
      # Convert a ScenarioReport into a \REopt Lite post
      #
      # [*parameters:*]
      #
      # * +scenario_report+ - _URBANopt::Scenario::DefaultReports::ScenarioReport_ - ScenarioReport to use in converting the +reopt_assumptions_hash+, if provided, to a \REopt Lite post. Otherwise, if the +reopt_assumptions_hash+ is nil a default post will be updated from this ScenarioReport and submitted to the \REopt Lite API. 
      # * +reopt_assumptions_hash+ - _Hash_ - Optional. A hash formatted for submittal to the \REopt Lite API containing default values. Values will be overwritten from the ScenarioReport where available (i.e. latitude, roof_squarefeet). Missing optional parameters will be filled in with default values by the API. 
      #
      # [*return:*] _Hash_ - Returns hash formatted for submittal to the \REopt Lite API
      ##
      def reopt_json_from_scenario_report(scenario_report, reopt_assumptions_json=nil)
        
        name = scenario_report.name.gsub ' ',''
        scenario_id = scenario_report.id.gsub ' ',''
        description = "scenario_report_#{name}_#{scenario_id}"

        #Create base REpopt Lite post
        reopt_inputs = {:Scenario => {:Site => {:ElectricTariff => {:blended_monthly_demand_charges_us_dollars_per_kw => [0,0,0,0,0,0,0,0,0,0,0,0], :blended_monthly_rates_us_dollars_per_kwh => [0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13,0.13]}, :LoadProfile => {},:Wind => {:max_kw => 0}}}}
        if !reopt_assumptions_json.nil?
          reopt_inputs = reopt_assumptions_json
        else
          @@logger.info('Using default REopt Lite assumptions')
        end

        #Update required info
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

        #Update required info
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

        #Update optional info
        if !scenario_report.program.roof_area.nil?
          reopt_inputs[:Scenario][:Site][:roof_squarefeet] = scenario_report.program.roof_area[:available_roof_area]
        end

        if !scenario_report.program.site_area.nil?
          reopt_inputs[:Scenario][:Site][:land_acres] = scenario_report.program.site_area * 1.0/43560 #acres/sqft
        end

        #Update load profile info
        begin
          col_num = scenario_report.timeseries_csv.column_names.index("Electricity:Facility")
          t = CSV.read(scenario_report.timeseries_csv.path,headers: true,converters: :numeric)
          energy_timeseries_kwh = t.by_col[col_num].map {|e| ((e or 0) * 0.293071)}  #convert kBTU to KWH

          if (scenario_report.timesteps_per_hour or 1) > 1
             energy_timeseries_kwh = energy_timeseries_kwh.each_slice(scenario_report.timesteps_per_hour).to_a.map {|x| x.inject(0, :+)/(x.length.to_f)}
          end

          if energy_timeseries_kwh.length < scenario_report.timesteps_per_hour * 8760
            energy_timeseries_kwh = energy_timeseries_kwh + [0]*((scenario_report.timesteps_per_hour * 8760) - energy_timeseries_kwh.length)
            @@logger.info("Assuming load profile for Scenario Report #{scenario_report.name} #{scenario_report.id} starts January 1 - filling in rest with zeros")
          end
          reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = energy_timeseries_kwh
        rescue
          raise "Could not parse the annual electric load from the timeseries csv - #{scenario_report.timeseries_csv.path}"
        end

        return reopt_inputs
      end


      ##
      # Converts a FeatureReport list from a ScenarioReport into an array of \REopt Lite posts
      #
      # [*parameters:*]
      #
      # * +scenario_report+ - _URBANopt::Scenario::DefaultReports::ScenarioReport_ - ScenarioReport to use in converting FeatureReports and respecitive +reopt_assumptions_hashes+, if provided, to a \REopt Lite post. If no +reopt_assumptions_hashes+ are provided default posts will be updated from these FeatureReports and submitted to the \REopt Lite API. 
      # * +reopt_assumptions_hashes+ - _Array_ - Optional. An array of hashes formatted for submittal to the \REopt Lite API containing default values. Values will be overwritten from the ScenarioReport where available (i.e. latitude, roof_squarefeet). Missing optional parameters will be filled in with default values by the API. The order should match the list in ScenarioReport.feature_reports.
      #
      # [*return:*] _Array_ - Returns an array of hashes formatted for submittal to the \REopt Lite API in the order of the FeatureReports lited in ScenarioReport.feature_reports.
      ##
      def reopt_jsons_from_scenario_feature_reports(scenario_report, reopt_assumptions_hashes = [])
        results = []
        adapter = URBANopt::REopt::FeatureReportAdapter.new

        scenario_report.feature_reports.each_with_index do |feature_report, idx|
          fr = adapter.reopt_json_from_feature_report(feature_report, reopt_assumptions_hashes[idx])
          results << fr
        end

        return results
      end

      ##
      # Updates a ScenarioReport from a \REopt Lite response
      #
      # [*parameters:*]
      #
      # * +scenario_report+ - _URBANopt::Scenario::DefaultReports::ScenarioReport_ - ScenarioReport to update from a \REopt Lite response.
      # * +reopt_output+ - _Hash_ - A hash response from the \REopt Lite API.
      # * +timeseries_csv_path+ - _String_ - Optional. The path to a file at which new timeseries data will be written. If not provided a file is created based on the run_uuid of the \REopt Lite optimization task.
      #
      # [*return:*] _URBANopt::Scenario::DefaultReports::ScenarioReport_ - Returns an updated ScenarioReport
      ##
      def update_scenario_report(scenario_report, reopt_output, timeseries_csv_path=nil)

        if reopt_output['outputs']['Scenario']['status'] != 'optimal'
          @@logger.info("Warning cannot Feature Report #{scenario_report.name} #{scenario_report.id}  - REopt optimization was non-optimal")
          return scenario_report
        end

        # Update location 
        scenario_report.location.latitude =   reopt_output['inputs']['Scenario']['Site']['latitude']
        scenario_report.location.longitude =   reopt_output['inputs']['Scenario']['Site']['longitude']
        
        # Update timeseries csv from \REopt Lite dispatch data
        scenario_report.timesteps_per_hour =  reopt_output['inputs']['Scenario']['time_steps_per_hour']

        # Update distributed generation sizing and financials
        scenario_report.distributed_generation.lcc_us_dollars = reopt_output['outputs']['Scenario']['Site']['Financial']['lcc_us_dollars']  or 0
        scenario_report.distributed_generation.npv_us_dollars = reopt_output['outputs']['Scenario']['Site']['Financial']['npv_us_dollars'] or 0
        scenario_report.distributed_generation.year_one_energy_cost_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_energy_cost_us_dollars']  or 0
        scenario_report.distributed_generation.year_one_demand_cost_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_demand_cost_us_dollars'] or 0
        scenario_report.distributed_generation.year_one_bill_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_bill_us_dollars'] or 0
        scenario_report.distributed_generation.total_energy_cost_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_energy_cost_us_dollars'] or 0

        scenario_report.distributed_generation.solar_pv.size_kw =  reopt_output['outputs']['Scenario']['Site']['PV']['size_kw']  or 0
        scenario_report.distributed_generation.wind.size_kw =  reopt_output['outputs']['Scenario']['Site']['Wind']['size_kw'] or 0
        scenario_report.distributed_generation.generator.size_kw =  reopt_output['outputs']['Scenario']['Site']['Generator']['size_kw'] or 0
        scenario_report.distributed_generation.storage.size_kw =  reopt_output['outputs']['Scenario']['Site']['Storage']['size_kw'] or 0
        scenario_report.distributed_generation.storage.size_kwh =  reopt_output['outputs']['Scenario']['Site']['Storage']['size_kwh'] or 0

        #Update dispatch
        generation_timeseries_kwh = Matrix[[0]*8760]
        unless reopt_output['outputs']['Scenario']['Site']['PV'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['PV']['size_kw'] or 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['PV']['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['PV']['year_one_power_production_series_kw']]
            end
          end
        end

        # unless reopt_output['outputs']['Scenario']['Site']['Storage'].nil?
        #   if (reopt_output['outputs']['Scenario']['Site']['Storage']['size_kw'] or 0) > 0
        #     if !reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw'].nil?
        #       generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw']]
        #     end
        #   end
        # end

        unless reopt_output['outputs']['Scenario']['Site']['Wind'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Wind']['size_kw'] or 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw']]
            end
          end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Generator'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Generator']['size_kw'] or 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw']]
            end
          end
        end
 
        $generation_timeseries_kwh = generation_timeseries_kwh.to_a[0] 
        $generation_timeseries_kwh_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Total")
        if $generation_timeseries_kwh_col.nil?
          $generation_timeseries_kwh_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Total")
        end

        $load = reopt_output['outputs']['Scenario']['Site']['LoadProfile']['year_one_electric_load_series_kw'] || [0]*8760
        $load_col = scenario_report.timeseries_csv.column_names.index("Electricity:Load:Total")
        if $load_col.nil?
          $load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("Electricity:Load:Total")
        end

        $utility_to_load = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_load_series_kw'] || [0]*8760
        $utility_to_load_col = scenario_report.timeseries_csv.column_names.index("Electricity:Grid:ToLoad")
        if $utility_to_load_col.nil?
          $utility_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("Electricity:Grid:ToLoad")
        end

        $utility_to_battery = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_battery_series_kw'] || [0]*8760
        $utility_to_battery_col = scenario_report.timeseries_csv.column_names.index("Electricity:Grid:ToBattery")
        if $utility_to_battery_col.nil?
          $utility_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("Electricity:Grid:ToBattery")
        end

        $storage_to_load = reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_load_series_kw'] || [0]*8760
        $storage_to_load_col = scenario_report.timeseries_csv.column_names.index("Electricity:Storage:ToLoad")
        if $storage_to_load_col.nil?
          $storage_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("Electricity:Storage:ToLoad")
        end

        $storage_to_grid = reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw'] || [0]*8760
        $storage_to_grid_col = scenario_report.timeseries_csv.column_names.index("Electricity:Storage:ToGrid")
        if $storage_to_grid_col.nil?
          $storage_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("Electricity:Storage:ToGrid")
        end

        $storage_soc = reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_soc_series_pct'] || [0]*8760
        $storage_soc_col = scenario_report.timeseries_csv.column_names.index("Electricity:Storage:StateOfCharge")
        if $storage_soc_col.nil?
          $storage_soc_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("Electricity:Storage:StateOfCharge")
        end

        $generator_total = reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'] || [0]*8760
        $generator_total_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Generator:Total")
        if $generator_total_col.nil?
          $generator_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Generator:Total")
        end

        $generator_to_battery = reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_battery_series_kw'] || [0]*8760
        $generator_to_battery_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Generator:ToBattery")
        if $generator_to_battery_col.nil?
          $generator_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Generator:ToBattery")
        end

        $generator_to_load = reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_load_series_kw'] || [0]*8760
        $generator_to_load_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Generator:ToLoad")
        if $generator_to_load_col.nil?
          $generator_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Generator:ToLoad")
        end

        $generator_to_grid = reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_grid_series_kw'] || [0]*8760
        $generator_to_grid_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Generator:ToGrid")
        if $generator_to_grid_col.nil?
          $generator_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Generator:ToGrid")
        end

        $pv_total = reopt_output['outputs']['Scenario']['Site']['PV']['year_one_power_production_series_kw'] || [0]*8760
        $pv_total_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:PV:Total")
        if $pv_total_col.nil?
          $pv_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:PV:Total")
        end

        $pv_to_battery = reopt_output['outputs']['Scenario']['Site']['PV']['year_one_to_battery_series_kw'] || [0]*8760
        $pv_to_battery_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:PV:ToBattery")
        if $pv_to_battery_col.nil?
          $pv_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:PV:ToBattery")
        end

        $pv_to_load = reopt_output['outputs']['Scenario']['Site']['PV']['year_one_to_load_series_kw'] || [0]*8760
        $pv_to_load_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:PV:ToLoad")
        if $pv_to_load_col.nil?
          $pv_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:PV:ToLoad")
        end

        $pv_to_grid = reopt_output['outputs']['Scenario']['Site']['PV']['year_one_to_grid_series_kw'] || [0]*8760
        $pv_to_grid_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:PV:ToGrid")
        if $pv_to_grid_col.nil?
          $pv_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:PV:ToGrid")
        end

        $wind_total = reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'] || [0]*8760
        $wind_total_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Wind:Total")
        if $wind_total_col.nil?
          $wind_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Wind:Total")
        end

        $wind_to_battery = reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_battery_series_kw'] || [0]*8760
        $wind_to_battery_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Wind:ToBattery")
        if $wind_to_battery_col.nil?
          $wind_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Wind:ToBattery")
        end

        $wind_to_load = reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_load_series_kw'] || [0]*8760
        $wind_to_load_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Wind:ToLoad")
        if $wind_to_load_col.nil?
          $wind_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Wind:ToLoad")
        end

        $wind_to_grid = reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_grid_series_kw'] || [0]*8760
        $wind_to_grid_col = scenario_report.timeseries_csv.column_names.index("ElectricityProduced:Wind:ToGrid")
        if $wind_to_grid_col.nil?
          $wind_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push("ElectricityProduced:Wind:ToGrid")
        end

        def modrow(x,i)  # :nodoc:
          x[$generation_timeseries_kwh_col] = $generation_timeseries_kwh[i] || 0
          x[$load_col] = $load[i] || 0
          x[$utility_to_load_col] = $utility_to_load[i] || 0
          x[$utility_to_battery_col] = $utility_to_battery[i] || 0
          x[$storage_to_load_col] = $storage_to_load[i] || 0
          x[$storage_to_grid_col] = $storage_to_grid[i] || 0
          x[$storage_soc_col] = $storage_soc[i] || 0
          x[$generator_total_col] = $generator_total[i] || 0
          x[$generator_to_battery_col] = $generator_to_battery[i] || 0
          x[$generator_to_load_col] = $generator_to_load[i] || 0
          x[$generator_to_grid_col] = $generator_to_grid[i] || 0
          x[$pv_total_col] = $pv_total[i] || 0
          x[$pv_to_battery_col] = $pv_to_battery[i] || 0
          x[$pv_to_load_col] = $pv_to_load[i] || 0
          x[$pv_to_grid_col] = $pv_to_grid[i] || 0
          x[$wind_total_col] = $wind_total[i] || 0
          x[$wind_to_battery_col] = $wind_to_battery[i] || 0
          x[$wind_to_load_col] = $wind_to_load[i] || 0
          x[$wind_to_grid_col] = $wind_to_grid[i] || 0
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
        mod_data[0] = scenario_report.timeseries_csv.column_names

        if timeseries_csv_path.nil?
          scenario_report.timeseries_csv.path = scenario_report.timeseries_csv.path.sub! '.csv',"_reopt#{reopt_output['inputs']['Scenario']['run_uuid']}.csv"
        else
          scenario_report.timeseries_csv.path = timeseries_csv_path
        end

        File.write(scenario_report.timeseries_csv.path, mod_data.map(&:to_csv).join)
        scenario_report.timeseries_csv.reload_data
        return scenario_report
      end
    end
  end
end