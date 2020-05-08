# *********************************************************************************
# URBANopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
# contributors. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************

require 'urbanopt/scenario/default_reports'
require 'urbanopt/reopt/reopt_logger'
require 'matrix'
require 'csv'
require 'time'

module URBANopt # :nodoc:
  module REopt # :nodoc:
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
      def reopt_json_from_scenario_report(scenario_report, reopt_assumptions_json = nil)
        name = scenario_report.name.delete ' '
        scenario_id = scenario_report.id.delete ' '
        description = "scenario_report_#{name}_#{scenario_id}"

        # Create base REpopt Lite post
        reopt_inputs = { Scenario: { Site: { ElectricTariff: { blended_monthly_demand_charges_us_dollars_per_kw: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], blended_monthly_rates_us_dollars_per_kwh: [0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13] }, LoadProfile: {}, Wind: { max_kw: 0 } } } }
        if !reopt_assumptions_json.nil?
          reopt_inputs = reopt_assumptions_json
        else
          @@logger.info('Using default REopt Lite assumptions')
        end

        # Update required info
        if scenario_report.location.latitude.nil? || scenario_report.location.longitude.nil? || (scenario_report.location.latitude == 0) || (scenario_report.location.longitude == 0)
          if !scenario_report.feature_reports.nil? && (scenario_report.feature_reports != [])
            lats = []
            longs = []
            scenario_report.feature_reports.each do |x|
              if ![nil, 0].include?(x[:location][:latitude]) && ![nil, 0].include?(x[:location][:longitude])
                lats.push(x[:location][:latitude])
                longs.push(x[:location][:longitude])
              end
            end

            if !lats.empty? && !longs.empty?
              scenario_report.location.latitude = lats.reduce(:+) / lats.size.to_f
              scenario_report.location.longitude = longs.reduce(:+) / longs.size.to_f
            end
          end
        end

        # Update required info
        requireds_names = ['latitude', 'longitude']
        requireds = [scenario_report.location.latitude, scenario_report.location.longitude]

        if requireds.include?(nil) || requireds.include?(0)
          requireds.each_with_index do |i, x|
            if [nil, 0].include? x
              n = requireds_names[i]
              raise "Missing value for #{n} - this is a required input"
            end
          end
        end

        reopt_inputs[:Scenario][:description] = description

        reopt_inputs[:Scenario][:Site][:latitude] = scenario_report.location.latitude
        reopt_inputs[:Scenario][:Site][:longitude] = scenario_report.location.longitude

        # Update optional info
        if !scenario_report.program.roof_area.nil?
          reopt_inputs[:Scenario][:Site][:roof_squarefeet] = scenario_report.program.roof_area[:available_roof_area]
        end

        if !scenario_report.program.site_area.nil?
          reopt_inputs[:Scenario][:Site][:land_acres] = scenario_report.program.site_area * 1.0 / 43560 # acres/sqft
        end

        unless scenario_report.timesteps_per_hour.nil?
          reopt_inputs[:Scenario][:time_steps_per_hour] = scenario_report.timesteps_per_hour
        end

        # Update load profile info
        begin
          col_num = scenario_report.timeseries_csv.column_names.index('Electricity:Facility(kWh)')
          t = CSV.read(scenario_report.timeseries_csv.path, headers: true, converters: :numeric)
          energy_timeseries_kw = t.by_col[col_num].map { |e| ((e * scenario_report.timesteps_per_hour || 0) ) }
          if energy_timeseries_kw.length < (scenario_report.timesteps_per_hour * 8760)
            start_date = Time.parse(t.by_col["Datetime"][0])
            start_ts = (((start_date.yday * 60.0 * 60.0 * 24) + (start_date.hour * 60.0 * 60.0) + (start_date.min * 60.0) + start_date.sec) /
                        (( 60 / scenario_report.timesteps_per_hour ) * 60)).to_int
            end_date = Time.parse(t.by_col["Datetime"][-1])
            end_ts = (((end_date.yday * 60.0 * 60.0 * 24) + (end_date.hour * 60.0 * 60.0) + (end_date.min * 60.0) + end_date.sec) /
                        (( 60 / scenario_report.timesteps_per_hour ) * 60)).to_int
            energy_timeseries_kw = [0.0]*(start_ts-1) + energy_timeseries_kw + [0.0]*((scenario_report.timesteps_per_hour * 8760) - end_ts)
          end
          reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = energy_timeseries_kw.map { |e| e ? e : 0 }[0,(scenario_report.timesteps_per_hour * 8760)]
        rescue StandardError
          @@logger.error("Could not parse the annual electric load from the timeseries csv - #{scenario_report.timeseries_csv.path}")
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
      def update_scenario_report(scenario_report, reopt_output, timeseries_csv_path = nil)
        if reopt_output['outputs']['Scenario']['status'] != 'optimal'
          @@logger.info("Warning cannot Feature Report #{scenario_report.name} #{scenario_report.id}  - REopt optimization was non-optimal")
          return scenario_report
        end
        
        $ts_per_hour = scenario_report.timesteps_per_hour
        def scale_timeseries(input, ts_per_hr=$ts_per_hour)
          if input.nil?
            return nil
          end
          if input.length ==0
            return nil
          end
          if input.length == (8760 * ts_per_hr)
            return input
          end
          result = []
          input.each do |val| 
            (1..ts_per_hr).each do |x|
              result.push(val/ts_per_hr.to_f)
            end
          end
          return result
        end

        # Update location
        scenario_report.location.latitude = reopt_output['inputs']['Scenario']['Site']['latitude']
        scenario_report.location.longitude = reopt_output['inputs']['Scenario']['Site']['longitude']

        # Update timeseries csv from \REopt Lite dispatch data
        scenario_report.timesteps_per_hour = reopt_output['inputs']['Scenario']['time_steps_per_hour']

        # Update distributed generation sizing and financials

        scenario_report.distributed_generation.lcc_us_dollars = reopt_output['outputs']['Scenario']['Site']['Financial']['lcc_us_dollars'] || 0
        scenario_report.distributed_generation.npv_us_dollars = reopt_output['outputs']['Scenario']['Site']['Financial']['npv_us_dollars'] || 0
        scenario_report.distributed_generation.year_one_energy_cost_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_energy_cost_us_dollars'] || 0
        scenario_report.distributed_generation.year_one_demand_cost_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_demand_cost_us_dollars'] || 0
        scenario_report.distributed_generation.year_one_bill_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_bill_us_dollars'] || 0
        scenario_report.distributed_generation.total_energy_cost_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_energy_cost_us_dollars'] || 0
        scenario_report.distributed_generation.total_demand_cost_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_demand_cost_us_dollars'] || 0
        scenario_report.distributed_generation.year_one_energy_cost_bau_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_energy_cost_bau_us_dollars'] || 0
        scenario_report.distributed_generation.year_one_demand_cost_bau_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_demand_cost_bau_us_dollars'] || 0
        scenario_report.distributed_generation.year_one_bill_bau_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_bill_bau_us_dollars'] || 0
        scenario_report.distributed_generation.total_demand_cost_bau_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_demand_cost_bau_us_dollars'] || 0
        scenario_report.distributed_generation.total_energy_cost_bau_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_energy_cost_bau_us_dollars'] || 0

        if reopt_output['outputs']['Scenario']['Site']['PV'].class == Hash
          reopt_output['outputs']['Scenario']['Site']['PV'] = [reopt_output['outputs']['Scenario']['Site']['PV']]
        elsif reopt_output['outputs']['Scenario']['Site']['PV'].nil?
          reopt_output['outputs']['Scenario']['Site']['PV'] = []
        end
        
        reopt_output['outputs']['Scenario']['Site']['PV'].each_with_index do |pv, i| 
          scenario_report.distributed_generation.add_tech 'solar_pv',  URBANopt::Scenario::DefaultReports::SolarPV.new( {size_kw: (pv['size_kw'] || 0), id: i })
        end

        wind = reopt_output['outputs']['Scenario']['Site']['Wind']
        if !wind['size_kw'].nil? and wind['size_kw'] != 0
          scenario_report.distributed_generation.add_tech 'wind',  URBANopt::Scenario::DefaultReports::Wind.new( {size_kw: (wind['size_kw'] || 0) })
        end

        generator = reopt_output['outputs']['Scenario']['Site']['Generator']
        if !generator['size_kw'].nil? and generator['size_kw'] != 0
          scenario_report.distributed_generation.add_tech 'generator',  URBANopt::Scenario::DefaultReports::Generator.new( {size_kw: (generator['size_kw'] || 0) })
        end

        storage = reopt_output['outputs']['Scenario']['Site']['Storage']
        if !storage['size_kw'].nil?  and storage['size_kw'] != 0
          scenario_report.distributed_generation.add_tech 'storage',  URBANopt::Scenario::DefaultReports::Storage.new( {size_kwh: (storage['size_kwh'] || 0), size_kw: (storage['size_kw'] || 0) })
        end
        
        generation_timeseries_kwh = Matrix[[0] * (8760 * scenario_report.timesteps_per_hour)]

        
        reopt_output['outputs']['Scenario']['Site']['PV'].each do |pv| 
          if (pv['size_kw'] || 0) > 0
            if !pv['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh += Matrix[pv['year_one_power_production_series_kw']]
            end
          end
         end

        unless reopt_output['outputs']['Scenario']['Site']['Storage'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Storage']['size_kw'] or 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw'].nil?
              generation_timeseries_kwh = generation_timeseries_kwh + Matrix[reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw']]
            end
          end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Wind'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Wind']['size_kw'] || 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh += Matrix[reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw']]
            end
          end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Generator'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Generator']['size_kw'] || 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh += Matrix[reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw']]
            end
          end
        end

        $generation_timeseries_kwh = generation_timeseries_kwh.to_a[0] || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generation_timeseries_kwh_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Total(kw)')
        if $generation_timeseries_kwh_col.nil?
          $generation_timeseries_kwh_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Total(kw)')
        end

        $load = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['LoadProfile']['year_one_electric_load_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $load_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Load:Total(kw)')
        if $load_col.nil?
          $load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Load:Total(kw)')
        end

        $utility_to_load = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_load_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $utility_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Grid:ToLoad(kw)')
        if $utility_to_load_col.nil?
          $utility_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Grid:ToLoad(kw)')
        end

        $utility_to_battery = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_battery_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $utility_to_battery_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Grid:ToBattery(kw)')
        if $utility_to_battery_col.nil?
          $utility_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Grid:ToBattery(kw)')
        end

        $storage_to_load = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_load_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $storage_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:ToLoad(kw)')
        if $storage_to_load_col.nil?
          $storage_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:ToLoad(kw)')
        end

        $storage_to_grid = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $storage_to_grid_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:ToGrid(kw)')
        if $storage_to_grid_col.nil?
          $storage_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:ToGrid(kw)')
        end

        $storage_soc = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_soc_series_pct']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $storage_soc_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:StateOfCharge(pct)')
        if $storage_soc_col.nil?
          $storage_soc_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:StateOfCharge(pct)')
        end

        $generator_total = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generator_total_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:Total(kw)')
        if $generator_total_col.nil?
          $generator_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:Total(kw)')
        end

        $generator_to_battery = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_battery_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generator_to_battery_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToBattery(kw)')
        if $generator_to_battery_col.nil?
          $generator_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToBattery(kw)')
        end

        $generator_to_load = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_load_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generator_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToLoad(kw)')
        if $generator_to_load_col.nil?
          $generator_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToLoad(kw)')
        end

        $generator_to_grid = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_grid_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generator_to_grid_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToGrid(kw)')
        if $generator_to_grid_col.nil?
          $generator_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToGrid(kw)')
        end

        $pv_total_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:Total(kw)')
        if $pv_total_col.nil?
          $pv_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:Total(kw)')
        end

        $pv_to_battery_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:ToBattery(kw)')
        if $pv_to_battery_col.nil?
          $pv_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:ToBattery(kw)')
        end

        $pv_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:ToLoad(kw)')
        if $pv_to_load_col.nil?
          $pv_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:ToLoad(kw)')
        end

        $pv_to_grid_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:ToGrid(kw)')
        if $pv_to_grid_col.nil?
          $pv_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:ToGrid(kw)')
        end

        $pv_total = Matrix[[0] * (8760 * scenario_report.timesteps_per_hour)]
        $pv_to_battery = Matrix[[0] * (8760 * scenario_report.timesteps_per_hour)]
        $pv_to_load = Matrix[[0] * (8760 * scenario_report.timesteps_per_hour)]
        $pv_to_grid = Matrix[[0] * (8760 * scenario_report.timesteps_per_hour)]

        reopt_output['outputs']['Scenario']['Site']['PV'].each_with_index do |pv, i|
          if (pv['size_kw'] || 0) > 0
            $pv_total += Matrix[scale_timeseries(pv['year_one_power_production_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)]
            $pv_to_battery += Matrix[scale_timeseries(pv['year_one_to_battery_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)]
            $pv_to_load += Matrix[scale_timeseries(pv['year_one_to_load_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)]
            $pv_to_grid += Matrix[scale_timeseries(pv['year_one_to_grid_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)]
          end
        end

        $pv_total = $pv_total.to_a[0]
        $pv_to_battery = $pv_to_battery.to_a[0]
        $pv_to_load = $pv_to_load.to_a[0]
        $pv_to_grid = $pv_to_grid.to_a[0]

        $wind_total = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_total_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:Total(kw)')
        if $wind_total_col.nil?
          $wind_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:Total(kw)')
        end

        $wind_to_battery = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_battery_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_to_battery_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToBattery(kw)')
        if $wind_to_battery_col.nil?
          $wind_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToBattery(kw)')
        end

        $wind_to_load = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_load_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToLoad(kw)')
        if $wind_to_load_col.nil?
          $wind_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToLoad(kw)')
        end

        $wind_to_grid = scale_timeseries(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_grid_series_kw']) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_to_grid_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToGrid(kw)')
        if $wind_to_grid_col.nil?
          $wind_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToGrid(kw)')
        end

        def modrow(x, i) # :nodoc:
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

        old_data = CSV.open(scenario_report.timeseries_csv.path).read
        start_date = Time.parse(old_data[1][0])
        start_ts = (((start_date.yday * 60.0 * 60.0 * 24) + (start_date.hour * 60.0 * 60.0) + (start_date.min * 60.0) + start_date.sec) / (( 60 / scenario_report.timesteps_per_hour ) * 60)).to_int
        mod_data = old_data.map.with_index do |x, i|
          if i > 0
            modrow(x, start_ts + i -2)
          else
            x
          end
        end
        mod_data[0] = scenario_report.timeseries_csv.column_names

        scenario_report.timeseries_csv.reload_data(mod_data)
        return scenario_report
      end
    end
  end
end
