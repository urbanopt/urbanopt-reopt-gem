# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'urbanopt/reporting/default_reports'
require 'urbanopt/reopt/reopt_logger'
require 'matrix'
require 'csv'
require 'time'
require_relative 'utilities'

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
      # * +scenario_report+ - _URBANopt::Reporting::DefaultReports::ScenarioReport_ - ScenarioReport to use in converting the +reopt_assumptions_hash+, if provided, to a \REopt Lite post. Otherwise, if the +reopt_assumptions_hash+ is nil a default post will be updated from this ScenarioReport and submitted to the \REopt Lite API.
      # * +reopt_assumptions_hash+ - _Hash_ - Optional. A hash formatted for submittal to the \REopt Lite API containing default values. Values will be overwritten from the ScenarioReport where available (i.e. latitude, roof_squarefeet). Missing optional parameters will be filled in with default values by the API.
      #
      # [*return:*] _Hash_ - Returns hash formatted for submittal to the \REopt Lite API
      ##
      def reopt_json_from_scenario_report(scenario_report, reopt_assumptions_json = nil, community_photovoltaic = nil)
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
        if (scenario_report.location.latitude_deg.nil? || scenario_report.location.longitude_deg.nil? || (scenario_report.location.latitude_deg == 0) || (scenario_report.location.longitude_deg == 0)) && (!scenario_report.feature_reports.nil? && (scenario_report.feature_reports != []))
          lats = []
          longs = []
          scenario_report.feature_reports.each do |x|
            @@logger.debug("Latitude '#{x.location.latitude_deg}' in feature report but not in scenario report. Adding it now.")
            if ![nil].include?(x.location.latitude_deg) && ![nil].include?(x.location.longitude_deg)
              lats.push(x.location.latitude_deg)
              longs.push(x.location.longitude_deg)
            end
          end

          if !lats.empty? && !longs.empty?
            scenario_report.location.latitude_deg = lats.reduce(:+) / lats.size.to_f
            scenario_report.location.longitude_deg = longs.reduce(:+) / longs.size.to_f
          end
        end

        # Update required info
        requireds_names = ['latitude', 'longitude']
        requireds = [scenario_report.location.latitude_deg, scenario_report.location.longitude_deg]

        if requireds.include?(nil) || requireds.include?(0)
          requireds.each_with_index do |x, i|
            if [nil].include? x
              n = requireds_names[i]
              raise "Missing value for #{n} - this is a required input"
            end
          end
        end

        reopt_inputs[:Scenario][:description] = description

        reopt_inputs[:Scenario][:Site][:latitude] = scenario_report.location.latitude_deg
        reopt_inputs[:Scenario][:Site][:longitude] = scenario_report.location.longitude_deg

        # Update optional info
        # REK: attribute names should be updated
        if reopt_inputs[:Scenario][:Site][:roof_squarefeet].nil? && !scenario_report.program.roof_area_sqft.nil?
          reopt_inputs[:Scenario][:Site][:roof_squarefeet] = scenario_report.program.roof_area_sqft[:available_roof_area_sqft]
        end

        begin
          if reopt_inputs[:Scenario][:Site][:land_acres].nil? && !community_photovoltaic[0][:properties][:footprint_area].nil?
            reopt_inputs[:Scenario][:Site][:land_acres] = community_photovoltaic[0][:properties][:footprint_area] * 1.0 / 43560 # acres/sqft
          end
        rescue StandardError
        end

        if reopt_inputs[:Scenario][:time_steps_per_hour].nil?
          reopt_inputs[:Scenario][:time_steps_per_hour] = 1
        end

        # Update load profile info
        begin
          col_num = scenario_report.timeseries_csv.column_names.index('Electricity:Facility(kWh)')
          t = CSV.read(scenario_report.timeseries_csv.path, headers: true, converters: :numeric)
          energy_timeseries_kw = t.by_col[col_num].map { |e| ((e * scenario_report.timesteps_per_hour || 0)) }
          if energy_timeseries_kw.length < (scenario_report.timesteps_per_hour * 8760)
            start_date = Time.parse(t.by_col['Datetime'][0])
            start_ts = (((start_date.yday * 60.0 * 60.0 * 24) + (start_date.hour * 60.0 * 60.0) + (start_date.min * 60.0) + start_date.sec) / \
                        ((60 / scenario_report.timesteps_per_hour) * 60)).to_int
            end_date = Time.parse(t.by_col['Datetime'][-1])
            end_ts = (((end_date.yday * 60.0 * 60.0 * 24) + (end_date.hour * 60.0 * 60.0) + (end_date.min * 60.0) + end_date.sec) / \
                        ((60 / scenario_report.timesteps_per_hour) * 60)).to_int
            energy_timeseries_kw = [0.0] * (start_ts - 1) + energy_timeseries_kw + [0.0] * ((scenario_report.timesteps_per_hour * 8760) - end_ts)
          end
          energy_timeseries_kw = energy_timeseries_kw.map { |e| e || 0 }[0, (scenario_report.timesteps_per_hour * 8760)]
        rescue StandardError
          @@logger.error("Could not parse the annual electric load from the timeseries csv - #{scenario_report.timeseries_csv.path}")
          raise "Could not parse the annual electric load from the timeseries csv - #{scenario_report.timeseries_csv.path}"
        end

        # Convert load to REopt Resolution
        begin
          reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = convert_powerflow_resolution(energy_timeseries_kw, scenario_report.timesteps_per_hour, reopt_inputs[:Scenario][:time_steps_per_hour])
        rescue StandardError
          @@logger.error("Could not convert the annual electric load from a resolution of #{scenario_report.timesteps_per_hour} to #{reopt_inputs[:Scenario][:time_steps_per_hour]}")
          raise "Could not convert the annual electric load from a resolution of #{scenario_report.timesteps_per_hour} to #{reopt_inputs[:Scenario][:time_steps_per_hour]}"
        end

        if reopt_inputs[:Scenario][:Site][:ElectricTariff][:coincident_peak_load_active_timesteps].nil?
          n_top_values = 100
          tmp1 = reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw]
          tmp2 = tmp1.each_index.max_by(n_top_values * reopt_inputs[:Scenario][:time_steps_per_hour]) { |i| tmp1[i] }
          for i in (0...tmp2.count)
            tmp2[i] += 1
          end
          reopt_inputs[:Scenario][:Site][:ElectricTariff][:coincident_peak_load_active_timesteps] = tmp2
        end

        if reopt_inputs[:Scenario][:Site][:ElectricTariff][:coincident_peak_load_charge_us_dollars_per_kw].nil?
          reopt_inputs[:Scenario][:Site][:ElectricTariff][:coincident_peak_load_charge_us_dollars_per_kw] = 0
        end

        return reopt_inputs
      end

      ##
      # Converts a FeatureReport list from a ScenarioReport into an array of \REopt Lite posts
      #
      # [*parameters:*]
      #
      # * +scenario_report+ - _URBANopt::Reporting::DefaultReports::ScenarioReport_ - ScenarioReport to use in converting FeatureReports and respecitive +reopt_assumptions_hashes+, if provided, to a \REopt Lite post. If no +reopt_assumptions_hashes+ are provided default posts will be updated from these FeatureReports and submitted to the \REopt Lite API.
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

      def modrow(data, idx) # :nodoc:
        data[$generation_timeseries_kwh_col] = $generation_timeseries_kwh[idx] || 0
        data[$load_col] = $load[idx] || 0
        data[$utility_to_load_col] = $utility_to_load[idx] || 0
        data[$utility_to_battery_col] = $utility_to_battery[idx] || 0
        data[$storage_to_load_col] = $storage_to_load[idx] || 0
        data[$storage_to_grid_col] = $storage_to_grid[idx] || 0
        data[$storage_soc_col] = $storage_soc[idx] || 0
        data[$generator_total_col] = $generator_total[idx] || 0
        data[$generator_to_battery_col] = $generator_to_battery[idx] || 0
        data[$generator_to_load_col] = $generator_to_load[idx] || 0
        data[$generator_to_grid_col] = $generator_to_grid[idx] || 0
        data[$pv_total_col] = $pv_total[idx] || 0
        data[$pv_to_battery_col] = $pv_to_battery[idx] || 0
        data[$pv_to_load_col] = $pv_to_load[idx] || 0
        data[$pv_to_grid_col] = $pv_to_grid[idx] || 0
        data[$wind_total_col] = $wind_total[idx] || 0
        data[$wind_to_battery_col] = $wind_to_battery[idx] || 0
        data[$wind_to_load_col] = $wind_to_load[idx] || 0
        data[$wind_to_grid_col] = $wind_to_grid[idx] || 0
        return data
      end

      ##
      # Updates a ScenarioReport from a \REopt Lite response
      #
      # [*parameters:*]
      #
      # * +scenario_report+ - _URBANopt::Reporting::DefaultReports::ScenarioReport_ - ScenarioReport to update from a \REopt Lite response.
      # * +reopt_output+ - _Hash_ - A hash response from the \REopt Lite API.
      # * +timeseries_csv_path+ - _String_ - Optional. The path to a file at which new timeseries data will be written. If not provided a file is created based on the run_uuid of the \REopt Lite optimization task.
      #
      # [*return:*] _URBANopt::Reporting::DefaultReports::ScenarioReport_ - Returns an updated ScenarioReport
      ##
      def update_scenario_report(scenario_report, reopt_output, timeseries_csv_path = nil, resilience_stats = nil)
        if reopt_output['outputs']['Scenario']['status'] != 'optimal'
          @@logger.info("Warning cannot Feature Report #{scenario_report.name} #{scenario_report.id}  - REopt optimization was non-optimal")
          return scenario_report
        end

        # Update location
        scenario_report.location.latitude_deg = reopt_output['inputs']['Scenario']['Site']['latitude']
        scenario_report.location.longitude_deg = reopt_output['inputs']['Scenario']['Site']['longitude']

        # Update distributed generation sizing and financials
        scenario_report.distributed_generation.annual_renewable_electricity_pct = reopt_output['outputs']['Scenario']['Site']['annual_renewable_electricity_pct'] || 0
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
        if !resilience_stats.nil?
          scenario_report.distributed_generation.resilience_hours_min = resilience_stats['resilience_hours_min']
          scenario_report.distributed_generation.resilience_hours_max = resilience_stats['resilience_hours_max']
          scenario_report.distributed_generation.resilience_hours_avg = resilience_stats['resilience_hours_avg']
          scenario_report.distributed_generation.probs_of_surviving = resilience_stats['probs_of_surviving']
          scenario_report.distributed_generation.probs_of_surviving_by_month = resilience_stats['probs_of_surviving_by_month']
          scenario_report.distributed_generation.probs_of_surviving_by_hour_of_the_day = resilience_stats['probs_of_surviving_by_hour_of_the_day']
        end

        if reopt_output['outputs']['Scenario']['Site']['PV'].instance_of?(Hash)
          reopt_output['outputs']['Scenario']['Site']['PV'] = [reopt_output['outputs']['Scenario']['Site']['PV']]
        elsif reopt_output['outputs']['Scenario']['Site']['PV'].nil?
          reopt_output['outputs']['Scenario']['Site']['PV'] = []
        end

        # Store the PV name and location in a hash
        location = {}
        azimuth = {}
        tilt = {}
        module_type = {}
        gcr = {}
        # Check whether multi PV assumption input file is used or single PV
        if reopt_output['inputs']['Scenario']['Site']['PV'].is_a?(Array)
          reopt_output['inputs']['Scenario']['Site']['PV'].each do |pv|
            location[pv['pv_name']] = pv['location']
            azimuth[pv['pv_name']] = pv['azimuth']
            tilt[pv['pv_name']] = pv['tilt']
            module_type[pv['pv_name']] = pv['module_type']
            gcr[pv['pv_name']] = pv['gcr']
          end
        else
          location[reopt_output['inputs']['Scenario']['Site']['PV']['pv_name']] = reopt_output['inputs']['Scenario']['Site']['PV']['location']
          azimuth[reopt_output['inputs']['Scenario']['Site']['PV']['pv_name']] = reopt_output['inputs']['Scenario']['Site']['PV']['azimuth']
          tilt[reopt_output['inputs']['Scenario']['Site']['PV']['pv_name']] = reopt_output['inputs']['Scenario']['Site']['PV']['tilt']
          module_type[reopt_output['inputs']['Scenario']['Site']['PV']['pv_name']] = reopt_output['inputs']['Scenario']['Site']['PV']['module_type']
          gcr[reopt_output['inputs']['Scenario']['Site']['PV']['pv_name']] = reopt_output['inputs']['Scenario']['Site']['PV']['gcr']
        end
        pv_inputs = reopt_output['inputs']['Scenario']['Site']['PV']
        if pv_inputs.is_a?(Hash)
          pv_inputs = [pv_inputs]
        end
        pv_outputs = reopt_output['outputs']['Scenario']['Site']['PV']
        if pv_outputs.is_a?(Hash)
          pv_outputs = [pv_outputs]
        end
        pv_outputs.each_with_index do |pv, i|
          if pv_inputs[i]
            if pv_inputs[i]['tilt']
              tilt[pv['pv_name']] = pv_inputs[i]['tilt']
            end
            if pv_inputs[i]['azimuth']
              azimuth[pv['pv_name']] = pv_inputs[i]['azimuth']
            end
            if pv_inputs[i]['module_type']
              module_type[pv['pv_name']] = pv_inputs[i]['module_type']
            end
          end
          scenario_report.distributed_generation.add_tech 'solar_pv', URBANopt::Reporting::DefaultReports::SolarPV.new({ size_kw: (pv['size_kw'] || 0), id: i, location: location[pv['pv_name']], average_yearly_energy_produced_kwh: pv['average_yearly_energy_produced_kwh'], azimuth: azimuth[pv['pv_name']], tilt: tilt[pv['pv_name']], module_type: module_type[pv['pv_name']], gcr: gcr[pv['pv_name']] })
        end

        wind = reopt_output['outputs']['Scenario']['Site']['Wind']
        if !wind['size_kw'].nil? && (wind['size_kw'] != 0)
          # find size_class
          size_class = nil
          if reopt_output['inputs']['Scenario']['Site']['Wind']['size_class']
            size_class = reopt_output['inputs']['Scenario']['Site']['Wind']['size_class']
          else
            size_class = 'commercial' # default
          end
          scenario_report.distributed_generation.add_tech 'wind', URBANopt::Reporting::DefaultReports::Wind.new({ size_kw: (wind['size_kw'] || 0), size_class: size_class, average_yearly_energy_produced_kwh: (wind['average_yearly_energy_produced_kwh'] || 0) })
        end

        generator = reopt_output['outputs']['Scenario']['Site']['Generator']
        if !generator['size_kw'].nil? && (generator['size_kw'] != 0)
          scenario_report.distributed_generation.add_tech 'generator', URBANopt::Reporting::DefaultReports::Generator.new({ size_kw: (generator['size_kw'] || 0) })
        end

        storage = reopt_output['outputs']['Scenario']['Site']['Storage']
        if !storage['size_kw'].nil? && (storage['size_kw'] != 0)
          scenario_report.distributed_generation.add_tech 'storage', URBANopt::Reporting::DefaultReports::Storage.new({ size_kwh: (storage['size_kwh'] || 0), size_kw: (storage['size_kw'] || 0) })
        end

        reopt_resolution = reopt_output['inputs']['Scenario']['time_steps_per_hour']
        generation_timeseries_kwh = Matrix[[0] * (8760 * scenario_report.timesteps_per_hour)]

        reopt_output['outputs']['Scenario']['Site']['PV'].each do |pv|
          if (pv['size_kw'] || 0) > 0 && !pv['year_one_power_production_series_kw'].nil?
            generation_timeseries_kwh += Matrix[convert_powerflow_resolution(pv['year_one_power_production_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour)]
          end
        end

        if !reopt_output['outputs']['Scenario']['Site']['Wind'].nil? && ((reopt_output['outputs']['Scenario']['Site']['Wind']['size_kw'] || 0) > 0) && !reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'].nil?
          generation_timeseries_kwh += Matrix[convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour)]
        end

        if !reopt_output['outputs']['Scenario']['Site']['Generator'].nil? && ((reopt_output['outputs']['Scenario']['Site']['Generator']['size_kw'] || 0) > 0) && !reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'].nil?
          generation_timeseries_kwh += Matrix[convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour)]
        end

        $generation_timeseries_kwh = generation_timeseries_kwh.to_a[0] || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generation_timeseries_kwh_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Total(kw)')
        if $generation_timeseries_kwh_col.nil?
          $generation_timeseries_kwh_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Total(kw)')
        end

        $load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['LoadProfile']['year_one_electric_load_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $load_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Load:Total(kw)')
        if $load_col.nil?
          $load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Load:Total(kw)')
        end

        $utility_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_load_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $utility_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Grid:ToLoad(kw)')
        if $utility_to_load_col.nil?
          $utility_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Grid:ToLoad(kw)')
        end

        $utility_to_battery = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_battery_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $utility_to_battery_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Grid:ToBattery(kw)')
        if $utility_to_battery_col.nil?
          $utility_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Grid:ToBattery(kw)')
        end

        $storage_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_load_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $storage_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:ToLoad(kw)')
        if $storage_to_load_col.nil?
          $storage_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:ToLoad(kw)')
        end

        $storage_to_grid = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $storage_to_grid_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:ToGrid(kw)')
        if $storage_to_grid_col.nil?
          $storage_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:ToGrid(kw)')
        end

        $storage_soc = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_soc_series_pct'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $storage_soc_col = scenario_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:StateOfCharge(pct)')
        if $storage_soc_col.nil?
          $storage_soc_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:StateOfCharge(pct)')
        end

        $generator_total = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generator_total_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:Total(kw)')
        if $generator_total_col.nil?
          $generator_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:Total(kw)')
        end

        $generator_to_battery = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_battery_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generator_to_battery_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToBattery(kw)')
        if $generator_to_battery_col.nil?
          $generator_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToBattery(kw)')
        end

        $generator_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_load_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $generator_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToLoad(kw)')
        if $generator_to_load_col.nil?
          $generator_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToLoad(kw)')
        end

        $generator_to_grid = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_grid_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
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
            $pv_total += Matrix[convert_powerflow_resolution(pv['year_one_power_production_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)]
            $pv_to_battery += Matrix[convert_powerflow_resolution(pv['year_one_to_battery_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)]
            $pv_to_load += Matrix[convert_powerflow_resolution(pv['year_one_to_load_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)]
            $pv_to_grid += Matrix[convert_powerflow_resolution(pv['year_one_to_grid_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)]
          end
        end

        $pv_total = $pv_total.to_a[0]
        $pv_to_battery = $pv_to_battery.to_a[0]
        $pv_to_load = $pv_to_load.to_a[0]
        $pv_to_grid = $pv_to_grid.to_a[0]

        $wind_total = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_total_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:Total(kw)')
        if $wind_total_col.nil?
          $wind_total_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:Total(kw)')
        end

        $wind_to_battery = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_battery_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_to_battery_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToBattery(kw)')
        if $wind_to_battery_col.nil?
          $wind_to_battery_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToBattery(kw)')
        end

        $wind_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_load_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_to_load_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToLoad(kw)')
        if $wind_to_load_col.nil?
          $wind_to_load_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToLoad(kw)')
        end

        $wind_to_grid = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_grid_series_kw'], reopt_resolution, scenario_report.timesteps_per_hour) || [0] * (8760 * scenario_report.timesteps_per_hour)
        $wind_to_grid_col = scenario_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToGrid(kw)')
        if $wind_to_grid_col.nil?
          $wind_to_grid_col = scenario_report.timeseries_csv.column_names.length
          scenario_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToGrid(kw)')
        end

        old_data = CSV.open(scenario_report.timeseries_csv.path).read
        start_date = Time.parse(old_data[1][0]) # Time is the end of the timestep
        start_ts = (
                      (
                        ((start_date.yday - 1) * 60.0 * 60.0 * 24) +
                        ((start_date.hour - 1) * 60.0 * 60.0) +
                        (start_date.min * 60.0) + start_date.sec) / \
                      ((60 / scenario_report.timesteps_per_hour) * 60)
                    ).to_int
        mod_data = old_data.map.with_index do |x, i|
          if i > 0
            modrow(x, start_ts + i - 1)
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
