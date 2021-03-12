# *********************************************************************************
# URBANopt (tm), Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC, and other
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

require 'urbanopt/reporting/default_reports'
require 'urbanopt/reopt/reopt_logger'
require 'csv'
require 'matrix'
require_relative 'utilities'
require 'time'

module URBANopt # :nodoc:
  module REopt # :nodoc:
    class FeatureReportAdapter
      ##
      # FeatureReportAdapter can convert a URBANopt::Reporting::DefaultReports::FeatureReport into a \REopt Lite posts or update a URBANopt::Reporting::DefaultReports::FeatureReport from a \REopt Lite response.
      ##
      # [*parameters:*]
      ##
      def initialize
        # initialize @@logger
        @@logger ||= URBANopt::REopt.reopt_logger
      end

      ##
      # Convert a FeatureReport into a \REopt Lite post
      #
      # [*parameters:*]
      #
      # * +feature_report+ - _URBANopt::Reporting::DefaultReports::FeatureReport_ - FeatureReport to use in converting the optional +reopt_assumptions_hash+ to a \REopt Lite post. If a +reopt_assumptions_hash+ is not provided, a default post will be updated from this FeatureReport and submitted to the \REopt Lite API.
      # *  +reopt_assumptions_hash+ - _Hash_ - Optional. A hash formatted for submittal to the \REopt Lite API containing default values. Values will be overwritten from the FeatureReport where available (i.e. latitude, roof_squarefeet). Missing optional parameters will be filled in with default values by the API.
      #
      # [*return:*] _Hash_ - Returns hash formatted for submittal to the \REopt Lite API
      ##
      def reopt_json_from_feature_report(feature_report, reopt_assumptions_hash = nil)
        name = feature_report.name.delete ' '
        description = "feature_report_#{name}_#{feature_report.id}"
        reopt_inputs = { Scenario: { Site: { ElectricTariff: { blended_monthly_demand_charges_us_dollars_per_kw: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], blended_monthly_rates_us_dollars_per_kwh: [0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13, 0.13] }, LoadProfile: {}, Wind: { max_kw: 0 } } } }
        if !reopt_assumptions_hash.nil?
          reopt_inputs = reopt_assumptions_hash
        else
          @@logger.info('Using default REopt Lite assumptions')
        end

        # Check FeatureReport has required data
        requireds_names = ['latitude', 'longitude']
        requireds = [feature_report.location.latitude_deg, feature_report.location.longitude_deg]

        if requireds.include?(nil) || requireds.include?(0)
          requireds.each_with_index do |i, x|
            if [nil].include? x
              n = requireds_names[i]
              # @@logger.error("Missing value for #{n} - this is a required input")
              raise "Missing value for #{n} - this is a required input"
            end
          end
        end

        reopt_inputs[:Scenario][:description] = description

        # Parse Location
        reopt_inputs[:Scenario][:Site][:latitude] = feature_report.location.latitude_deg
        reopt_inputs[:Scenario][:Site][:longitude] = feature_report.location.longitude_deg

        # Parse Optional FeatureReport metrics - do not overwrite from assumptions file
        if reopt_inputs[:Scenario][:Site][:roof_squarefeet].nil?
          unless feature_report.program.roof_area_sqft.nil?
            reopt_inputs[:Scenario][:Site][:roof_squarefeet] = feature_report.program.roof_area_sqft[:available_roof_area_sqft]
          end
        end

        if reopt_inputs[:Scenario][:Site][:land_acres].nil?
          unless feature_report.program.site_area_sqft.nil?
            reopt_inputs[:Scenario][:Site][:land_acres] = feature_report.program.site_area_sqft * 1.0 / 43560 # acres/sqft
          end
        end

        if reopt_inputs[:Scenario][:time_steps_per_hour].nil?
          reopt_inputs[:Scenario][:time_steps_per_hour] = 1
        end

        # Parse Load Profile
        begin
          #Convert kWh values in the timeseries CSV to kW
          col_num = feature_report.timeseries_csv.column_names.index('Electricity:Facility(kWh)')
          t = CSV.read(feature_report.timeseries_csv.path, headers: true, converters: :numeric)
          energy_timeseries_kw = t.by_col[col_num].map { |e| ((e * feature_report.timesteps_per_hour || 0) ) }
          #Fill in missing timestep values with 0 if a full year is not provided
          if energy_timeseries_kw.length < (feature_report.timesteps_per_hour * 8760)
            start_date = Time.parse(t.by_col["Datetime"][0])
            start_ts = (((start_date.yday * 60.0 * 60.0 * 24) + (start_date.hour * 60.0 * 60.0) + (start_date.min * 60.0) + start_date.sec) /
                        (( 60 / feature_report.timesteps_per_hour ) * 60)).to_int
            end_date = Time.parse(t.by_col["Datetime"][-1])
            end_ts = (((end_date.yday * 60.0 * 60.0 * 24) + (end_date.hour * 60.0 * 60.0) + (end_date.min * 60.0) + end_date.sec) /
                        (( 60 / feature_report.timesteps_per_hour ) * 60)).to_int
            energy_timeseries_kw = [0.0]*(start_ts-1) + energy_timeseries_kw + [0.0]*((feature_report.timesteps_per_hour * 8760) - end_ts)
          end          
          #Clip to one non-leap year's worth of data
          energy_timeseries_kw = energy_timeseries_kw.map { |e| e ? e : 0 }[0,(feature_report.timesteps_per_hour * 8760)]
          #Convert from the OpenDSS resolution to the REopt Lite resolution, if necessary
        rescue StandardError
          @@logger.error("Could not parse the annual electric load from the timeseries csv - #{feature_report.timeseries_csv.path}")
          raise "Could not parse the annual electric load from the timeseries csv - #{feature_report.timeseries_csv.path}"
        end
        
        # Convert load to REopt Resolution
        begin
          reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw] = convert_powerflow_resolution(energy_timeseries_kw, feature_report.timesteps_per_hour, reopt_inputs[:Scenario][:time_steps_per_hour])
          
        rescue
          @@logger.error("Could not convert the annual electric load from a resolution of #{feature_report.timesteps_per_hour} to #{reopt_inputs[:Scenario][:time_steps_per_hour]}")
          raise "Could not convert the annual electric load from a resolution of #{feature_report.timesteps_per_hour} to #{reopt_inputs[:Scenario][:time_steps_per_hour]}"
        end
        
        if reopt_inputs[:Scenario][:Site][:ElectricTariff][:coincident_peak_load_active_timesteps].nil?
          n_top_values = 100
          tmp1 = reopt_inputs[:Scenario][:Site][:LoadProfile][:loads_kw]
          tmp2 = tmp1.each_index.max_by(n_top_values*reopt_inputs[:Scenario][:time_steps_per_hour]){|i| tmp1[i]} 
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
      # Update a FeatureReport from a \REopt Lite response
      #
      # [*parameters:*]
      #
      # * +feature_report+ - _URBANopt::Reporting::DefaultReports::FeatureReport_ - FeatureReport to update from a \REopt Lite reponse hash.
      # * +reopt_output+ - _Hash_ - A reponse hash from the \REopt Lite API to use in overwriting FeatureReport technology sizes, costs and dispatch strategies.
      # * +timeseries_csv_path+ - _String_ - Optional. The path to a file at which a new timeseries CSV will be written. If not provided a file is created based on the run_uuid of the \REopt Lite optimization task.
      #
      # [*return:*] _URBANopt::Reporting::DefaultReports::FeatureReport_ - Returns an updated FeatureReport.
      ##
      def update_feature_report(feature_report, reopt_output, timeseries_csv_path=nil, resilience_stats=nil)
        # Check if the \REopt Lite response is valid
        if reopt_output['outputs']['Scenario']['status'] != 'optimal'
          @@logger.info("Warning cannot Feature Report #{feature_report.name} #{feature_report.id}  - REopt optimization was non-optimal")
          return feature_report
        end
 
        # Update location
        feature_report.location.latitude_deg = reopt_output['inputs']['Scenario']['Site']['latitude']
        feature_report.location.longitude_deg = reopt_output['inputs']['Scenario']['Site']['longitude']

        # Update distributed generation sizing and financials
        feature_report.distributed_generation.lcc_us_dollars = reopt_output['outputs']['Scenario']['Site']['Financial']['lcc_us_dollars'] || 0
        feature_report.distributed_generation.npv_us_dollars = reopt_output['outputs']['Scenario']['Site']['Financial']['npv_us_dollars'] || 0
        feature_report.distributed_generation.year_one_energy_cost_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_energy_cost_us_dollars'] || 0
        feature_report.distributed_generation.year_one_demand_cost_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_demand_cost_us_dollars'] || 0
        feature_report.distributed_generation.year_one_bill_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_bill_us_dollars'] || 0
        feature_report.distributed_generation.total_energy_cost_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_energy_cost_us_dollars'] || 0
        feature_report.distributed_generation.total_demand_cost_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_demand_cost_us_dollars'] || 0
        feature_report.distributed_generation.year_one_energy_cost_bau_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_energy_cost_bau_us_dollars'] || 0
        feature_report.distributed_generation.year_one_demand_cost_bau_us_dollars =  reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_demand_cost_bau_us_dollars'] || 0
        feature_report.distributed_generation.year_one_bill_bau_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_bill_bau_us_dollars'] || 0
        feature_report.distributed_generation.total_demand_cost_bau_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_demand_cost_bau_us_dollars'] || 0
        feature_report.distributed_generation.total_energy_cost_bau_us_dollars = reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['total_energy_cost_bau_us_dollars'] || 0
        if !resilience_stats.nil?
          feature_report.distributed_generation.resilience_hours_min = resilience_stats['resilience_hours_min']
          feature_report.distributed_generation.resilience_hours_max = resilience_stats['resilience_hours_max']
          feature_report.distributed_generation.resilience_hours_avg = resilience_stats['resilience_hours_avg']
          feature_report.distributed_generation.probs_of_surviving = resilience_stats['probs_of_surviving']
          feature_report.distributed_generation.probs_of_surviving_by_month = resilience_stats['probs_of_surviving_by_month']
          feature_report.distributed_generation.probs_of_surviving_by_hour_of_the_day = resilience_stats['probs_of_surviving_by_hour_of_the_day']  
        end
        
        if reopt_output['outputs']['Scenario']['Site']['PV'].class == Hash
          reopt_output['outputs']['Scenario']['Site']['PV'] = [reopt_output['outputs']['Scenario']['Site']['PV']]
        elsif reopt_output['outputs']['Scenario']['Site']['PV'].nil?
          reopt_output['outputs']['Scenario']['Site']['PV'] = []
        end

        reopt_output['outputs']['Scenario']['Site']['PV'].each_with_index do |pv, i|
          feature_report.distributed_generation.add_tech 'solar_pv',  URBANopt::Reporting::DefaultReports::SolarPV.new( {size_kw: (pv['size_kw'] || 0), id: i })
        end

        wind = reopt_output['outputs']['Scenario']['Site']['Wind']
        if !wind['size_kw'].nil? and wind['size_kw'] != 0
          feature_report.distributed_generation.add_tech 'wind',  URBANopt::Reporting::DefaultReports::Wind.new( {size_kw: (wind['size_kw'] || 0) })
        end

        generator = reopt_output['outputs']['Scenario']['Site']['Generator']
        if !generator['size_kw'].nil? and generator['size_kw'] != 0
          feature_report.distributed_generation.add_tech 'generator',  URBANopt::Reporting::DefaultReports::Generator.new( {size_kw: (generator['size_kw'] || 0) })
        end

        storage = reopt_output['outputs']['Scenario']['Site']['Storage']
        if !storage['size_kw'].nil?  and storage['size_kw'] != 0
          feature_report.distributed_generation.add_tech 'storage',  URBANopt::Reporting::DefaultReports::Storage.new( {size_kwh: (storage['size_kwh'] || 0), size_kw: (storage['size_kw'] || 0) })
        end

        generation_timeseries_kwh = Matrix[[0] * (8760 * feature_report.timesteps_per_hour)]
        reopt_resolution = reopt_output['inputs']['Scenario']['time_steps_per_hour']

        unless reopt_output['outputs']['Scenario']['Site']['PV'].nil?
          reopt_output['outputs']['Scenario']['Site']['PV'].each do |pv|
            if (pv['size_kw'] || 0) > 0
              if !pv['year_one_power_production_series_kw'].nil?
                generation_timeseries_kwh += Matrix[convert_powerflow_resolution(pv['year_one_power_production_series_kw'], reopt_resolution, feature_report.timesteps_per_hour)]
              end
            end
           end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Wind'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Wind']['size_kw'] || 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh += Matrix[convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'], reopt_resolution, feature_report.timesteps_per_hour)]
            end
          end
        end

        unless reopt_output['outputs']['Scenario']['Site']['Generator'].nil?
          if (reopt_output['outputs']['Scenario']['Site']['Generator']['size_kw'] || 0) > 0
            if !reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'].nil?
              generation_timeseries_kwh += Matrix[convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'], reopt_resolution, feature_report.timesteps_per_hour)]
            end
          end
        end

        $generation_timeseries_kwh = generation_timeseries_kwh.to_a[0] || [0] * (8760 * feature_report.timesteps_per_hour)
        $generation_timeseries_kwh_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Total(kw)')
        if $generation_timeseries_kwh_col.nil?
          $generation_timeseries_kwh_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Total(kw)')
        end

        $load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['LoadProfile']['year_one_electric_load_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $load_col = feature_report.timeseries_csv.column_names.index('REopt:Electricity:Load:Total(kw)')
        if $load_col.nil?
          $load_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:Electricity:Load:Total(kw)')
        end

        $utility_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_load_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $utility_to_load_col = feature_report.timeseries_csv.column_names.index('REopt:Electricity:Grid:ToLoad(kw)')
        if $utility_to_load_col.nil?
          $utility_to_load_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:Electricity:Grid:ToLoad(kw)')
        end

        $utility_to_battery = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['ElectricTariff']['year_one_to_battery_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $utility_to_battery_col = feature_report.timeseries_csv.column_names.index('REopt:Electricity:Grid:ToBattery(kw)')
        if $utility_to_battery_col.nil?
          $utility_to_battery_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:Electricity:Grid:ToBattery(kw)')
        end

        $storage_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_load_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $storage_to_load_col = feature_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:ToLoad(kw)')
        if $storage_to_load_col.nil?
          $storage_to_load_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:ToLoad(kw)')
        end

        $storage_to_grid = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_to_grid_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $storage_to_grid_col = feature_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:ToGrid(kw)')
        if $storage_to_grid_col.nil?
          $storage_to_grid_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:ToGrid(kw)')
        end

        $storage_soc = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Storage']['year_one_soc_series_pct'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $storage_soc_col = feature_report.timeseries_csv.column_names.index('REopt:Electricity:Storage:StateOfCharge(pct)')
        if $storage_soc_col.nil?
          $storage_soc_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:Electricity:Storage:StateOfCharge(pct)')
        end

        $generator_total = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_power_production_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $generator_total_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:Total(kw)')
        if $generator_total_col.nil?
          $generator_total_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:Total(kw)')
        end

        $generator_to_battery = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_battery_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $generator_to_battery_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToBattery(kw)')
        if $generator_to_battery_col.nil?
          $generator_to_battery_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToBattery(kw)')
        end

        $generator_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_load_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $generator_to_load_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToLoad(kw)')
        if $generator_to_load_col.nil?
          $generator_to_load_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToLoad(kw)')
        end

        $generator_to_grid = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Generator']['year_one_to_grid_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $generator_to_grid_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Generator:ToGrid(kw)')
        if $generator_to_grid_col.nil?
          $generator_to_grid_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Generator:ToGrid(kw)')
        end

        $pv_total_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:Total(kw)')
        if $pv_total_col.nil?
          $pv_total_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:Total(kw)')
        end

        $pv_to_battery_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:ToBattery(kw)')
        if $pv_to_battery_col.nil?
          $pv_to_battery_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:ToBattery(kw)')
        end

        $pv_to_load_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:ToLoad(kw)')
        if $pv_to_load_col.nil?
          $pv_to_load_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:ToLoad(kw)')
        end


        $pv_to_grid_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:PV:ToGrid(kw)')
        if $pv_to_grid_col.nil?
          $pv_to_grid_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:PV:ToGrid(kw)')
        end

        $pv_total = Matrix[[0] * (8760 * feature_report.timesteps_per_hour)]
        $pv_to_battery = Matrix[[0] * (8760 * feature_report.timesteps_per_hour)]
        $pv_to_load = Matrix[[0] * (8760 * feature_report.timesteps_per_hour)]
        $pv_to_grid = Matrix[[0] * (8760 * feature_report.timesteps_per_hour)]

        reopt_output['outputs']['Scenario']['Site']['PV'].each_with_index do |pv, i|
          if (pv['size_kw'] || 0) > 0
            $pv_total += Matrix[convert_powerflow_resolution(pv['year_one_power_production_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)]
            $pv_to_battery += Matrix[convert_powerflow_resolution(pv['year_one_to_battery_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)]
            $pv_to_load += Matrix[convert_powerflow_resolution(pv['year_one_to_load_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)]
            $pv_to_grid += Matrix[convert_powerflow_resolution(pv['year_one_to_grid_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)]
          end
        end

        $pv_total = $pv_total.to_a[0]
        $pv_to_battery = $pv_to_battery.to_a[0]
        $pv_to_load = $pv_to_load.to_a[0]
        $pv_to_grid = $pv_to_grid.to_a[0]

        $wind_total = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_power_production_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $wind_total_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:Total(kw)')
        if $wind_total_col.nil?
          $wind_total_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:Total(kw)')
        end

        $wind_to_battery = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_battery_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $wind_to_battery_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToBattery(kw)')
        if $wind_to_battery_col.nil?
          $wind_to_battery_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToBattery(kw)')
        end

        $wind_to_load = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_load_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $wind_to_load_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToLoad(kw)')
        if $wind_to_load_col.nil?
          $wind_to_load_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToLoad(kw)')
        end

        $wind_to_grid = convert_powerflow_resolution(reopt_output['outputs']['Scenario']['Site']['Wind']['year_one_to_grid_series_kw'], reopt_resolution, feature_report.timesteps_per_hour) || [0] * (8760 * feature_report.timesteps_per_hour)
        $wind_to_grid_col = feature_report.timeseries_csv.column_names.index('REopt:ElectricityProduced:Wind:ToGrid(kw)')
        if $wind_to_grid_col.nil?
          $wind_to_grid_col = feature_report.timeseries_csv.column_names.length
          feature_report.timeseries_csv.column_names.push('REopt:ElectricityProduced:Wind:ToGrid(kw)')
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

        old_data = CSV.open(feature_report.timeseries_csv.path).read
        start_date = Time.parse(old_data[1][0])
        start_ts = (
                      (
                        ((start_date.yday - 1) * 60.0 * 60.0 * 24) + 
                        (((start_date.hour)  - 1) * 60.0 * 60.0) + 
                        (start_date.min * 60.0) + start_date.sec ) /
                      (( 60 / scenario_report.timesteps_per_hour ) * 60)
                    ).to_int

        mod_data = old_data.map.with_index do |x, i|
          if i > 0
            modrow(x, start_ts + i -2)
          else
            x
          end
        end

        mod_data[0] = feature_report.timeseries_csv.column_names

        feature_report.timeseries_csv.reload_data(mod_data)
        return feature_report
      end
    end
  end
end
