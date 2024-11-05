# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

module URBANopt # :nodoc:
  module REopt # :nodoc:
    class REoptGHPAdapter

      def initialize
        # initialize @@logger
        @@logger ||= URBANopt::REopt.reopt_logger
      end

      def create_reopt_input_building(run_dir, system_parameter_hash, reopt_ghp_assumptions_hash, building_id, modelica_result)
        reopt_inputs_building = {}
        if !reopt_ghp_assumptions_hash.nil?
          reopt_inputs_building = reopt_ghp_assumptions_hash
        else
          @@logger.info('Using default REopt assumptions')
          # create a dictionary for REopt Inputs
          reopt_inputs_building = {
            Site: {},
            SpaceHeatingLoad: {},
            DomesticHotWaterLoad: {},
            ElectricLoad: {},
            ElectricTariff: {
              urdb_label: ""
            },
            GHP: {},
            ExistingBoiler: {}
          }
        end

        # The URDB label is required to be specified in the input assumption file
        if reopt_inputs_building[:ElectricTariff][:urdb_label].nil? || reopt_inputs_building[:ElectricTariff][:urdb_label].empty?
          raise "Missing value for urdb_label - this is a required input"
        end

        scenario_json_path = File.join(run_dir, "default_scenario_report.json")
        if File.exist?(scenario_json_path)
          File.open(scenario_json_path, 'r') do |file|
            scenario_json_data = JSON.parse(file.read, symbolize_names: true)              
            # update site location
            @latitude = scenario_json_data[:scenario_report][:location][:latitude_deg]
            @longitude = scenario_json_data[:scenario_report][:location][:longitude_deg]
            reopt_inputs_building[:Site][:latitude] = @latitude
            reopt_inputs_building[:Site][:longitude] = @longitude

          end
        end

        reopt_inputs_building[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour] = []
        # Read the default csv report
        default_feature_report_path = File.join(run_dir, building_id.to_s, "feature_reports", "default_feature_report.csv")
        if File.exist?(default_feature_report_path)
          timeseries_data = CSV.read(default_feature_report_path, headers: true)
            
          # Initialize the total kBtu sum
          total_kbtu = 0.0

          # Convert each value in "Heating:NaturalGas(kBtu)" to MMBtu and store in the array
          timeseries_data.each do |row|
            if row['Heating:NaturalGas(kBtu)'] # Ensure the value exists
              kBtu_value = row['Heating:NaturalGas(kBtu)'].to_f # Convert to float
              total_kbtu += kBtu_value # Sum kBtu values
            end
          end
            # Check if the total kBtu is zero
          if total_kbtu.zero?
            # If zero, populate with 8760 values of 1.0 MMBtu (if you mean 1.0 for each hour)
            reopt_inputs_building[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour] = [0.0001] * 8760
          else
            # If not zero, convert and append to the array
            timeseries_data.each do |row|
              if row['Heating:NaturalGas(kBtu)'] # Ensure the value exists
                kBtu_value = row['Heating:NaturalGas(kBtu)'].to_f # Convert to float
                mMBtu_value = kBtu_value / 1000 # Convert kBtu to MMBtu
                reopt_inputs_building[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour] << mMBtu_value # Append to the array
              end
            end
          end

        else
          # Calculate space heating load
          reopt_inputs_building[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour] = [0.000001] * 8760
          puts "Existing heating fuel cost was not taken into consideration in result calculations."
        end
        
        # read_modelica_result
        modelica_project = File.expand_path(modelica_result)
        project_name = File.basename(modelica_project)
        @modelica_csv = File.join(
          modelica_project,
          "#{project_name}.Districts.DistrictEnergySystem_results",
          "#{project_name}.Districts.DistrictEnergySystem_result.csv"
        )

        if File.exist?(@modelica_csv)
          modelica_data = CSV.read(@modelica_csv, headers: true)
          heating_power = "heating_electric_power_#{building_id}"
          cooling_power = "cooling_electric_power_#{building_id}"
          pump_power = "pump_power_#{building_id}"
          ets_pump_power = "ets_pump_power_#{building_id}"
          heating_system_capacity = "heating_system_capacity_#{building_id}"
          cooling_system_capacity = "cooling_system_capacity_#{building_id}"

          heating_power_values = cooling_power_values = pump_power_values = ets_pump_power_values = []
          total_electric_load_building = []
          # Ensure the column exists
          if modelica_data.headers.include?(heating_power)
            heating_power_values = modelica_data[heating_power]
          end
          if modelica_data.headers.include?(cooling_power)
            cooling_power_values = modelica_data[cooling_power]
          end
          if modelica_data.headers.include?(pump_power)
            pump_power_values = modelica_data[pump_power]
          end
          if modelica_data.headers.include?(ets_pump_power)
            ets_pump_power_values = modelica_data[ets_pump_power]
          end 

          total_electric_load_building = heating_power_values.zip(cooling_power_values, pump_power_values, ets_pump_power_values).map do |elements|
            elements.map { |e| e.to_f / 1000 }.sum
          end

          peak_combined_heatpump_thermal_ton = 0

          if modelica_data.headers.include?(heating_system_capacity)
            heating_system_capacity_value = modelica_data[heating_system_capacity][0]
          end
          if modelica_data.headers.include?(cooling_system_capacity)
            cooling_system_capacity_value = modelica_data[cooling_system_capacity][0]
          end

          peak_combined_heatpump_thermal_ton = ([heating_system_capacity_value.to_f.abs, cooling_system_capacity_value.to_f.abs].max)/3517

          # Store the result in reopt_inputs_building ElectricLoad
          reopt_inputs_building[:ElectricLoad][:loads_kw] = total_electric_load_building


          domestic_hot_water = total_electric_load_building.map do |load|
            load * 0
          end

          # This is not used in REopt calculation but required for formatting.
          reopt_inputs_building[:DomesticHotWaterLoad][:fuel_loads_mmbtu_per_hour] = domestic_hot_water

          # Add GHP Fields
          reopt_inputs_building[:GHP] = {}  
          # REopt default
          reopt_inputs_building[:GHP][:require_ghp_purchase] = 1
          reopt_inputs_building[:GHP][:om_cost_per_sqft_year] = 0
          reopt_inputs_building[:GHP][:heatpump_capacity_sizing_factor_on_peak_load] = 1.0
          # Add the floor area
          building_json_path = File.join(run_dir, building_id.to_s, "feature_reports", "default_feature_report.json")          
          if File.exist?(building_json_path)
            File.open(building_json_path, 'r') do |file|
              building_json_data = JSON.parse(file.read, symbolize_names: true)
              reopt_inputs_building[:GHP][:building_sqft] = building_json_data[:program][:floor_area_sqft]
            end
          else
            puts "File not found: #{building_json_path}"
          end

          # Add existing boiler fuel cost
          # TODO : Add this as optional user input
          reopt_inputs_building[:ExistingBoiler][:fuel_cost_per_mmbtu] = 13.5
        
          # Add ghpghx_responses
          ghpghx_output = {}
          ghpghx_output[:outputs] = {}
          ghpghx_output[:inputs] = {}
          ghpghx_output[:outputs][:heat_pump_configuration] = "WSHP"
          # This is not used in REopt calculation but required for formatting.
          ghpghx_output[:outputs][:yearly_ghx_pump_electric_consumption_series_kw] = [0] * 8760
          ghpghx_output[:outputs][:number_of_boreholes] = 0 
          ghpghx_output[:outputs][:length_boreholes_ft] = 0

          ghpghx_output[:outputs][:peak_combined_heatpump_thermal_ton] = peak_combined_heatpump_thermal_ton
          ghpghx_output[:outputs][:yearly_total_electric_consumption_kwh] = total_electric_load_building.sum
          ghpghx_output[:outputs][:yearly_total_electric_consumption_series_kw] = total_electric_load_building
          ghpghx_output[:outputs][:yearly_heating_heatpump_electric_consumption_series_kw] = total_electric_load_building
          ghpghx_output[:outputs][:yearly_cooling_heatpump_electric_consumption_series_kw] = [0] * 8760
          
          ghpghx_output[:inputs][:heating_thermal_load_mmbtu_per_hr] = [0.001] * 8760
          ghpghx_output[:inputs][:cooling_thermal_load_ton] = [0] * 8760
      
          ghpghx_output_all = [ghpghx_output]
          reopt_inputs_building[:GHP][:ghpghx_responses] = {}
          reopt_inputs_building[:GHP][:ghpghx_responses] = ghpghx_output_all

        end
      
        #save output report in reopt_ghp directory
        reopt_ghp_dir = File.join(run_dir, "reopt_ghp", "reopt_ghp_inputs")
        json_file_path = File.join(reopt_ghp_dir, "GHP_building_#{building_id}.json")
        pretty_json = JSON.pretty_generate(reopt_inputs_building)
        File.write(json_file_path, pretty_json)

      end

      def create_reopt_input_district(run_dir, system_parameter_hash, reopt_ghp_assumptions_hash, ghp_id, modelica_result)

        reopt_inputs_district = {}

        if !reopt_ghp_assumptions_hash.nil?
          reopt_inputs_district = reopt_ghp_assumptions_hash
        else
          @@logger.info('Using default REopt assumptions')
          # create a dictionary for REopt Inputs
          reopt_inputs_district = {
            Site: {},
            SpaceHeatingLoad: {},
            DomesticHotWaterLoad: {},
            ElectricLoad: {},
            ElectricTariff: {
              "urdb_label": ""
            },
            GHP: {},
            ExistingBoiler: {}
          }
        end
    
        reopt_inputs_district[:Site] = {}
        reopt_inputs_district[:Site][:latitude] = @latitude
        reopt_inputs_district[:Site][:longitude] = @longitude
        # The URDB label is required to be specified in the input assumption file
        if reopt_inputs_district[:ElectricTariff][:urdb_label].nil? || reopt_inputs_district[:ElectricTariff][:urdb_label].empty?

          raise "Missing value for urdb_label - this is a required input"
        
        end

        reopt_inputs_district[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour] = [1]*8760
        reopt_inputs_district[:DomesticHotWaterLoad][:fuel_loads_mmbtu_per_hour] = [0.0000001]*8760

        reopt_inputs_district[:ElectricLoad] = {}
        
        # TEMPORARY
        #reopt_inputs_district[:ElectricLoad][:loads_kw] = [0.00001]*8760
        
        reopt_inputs_district[:ExistingBoiler] = {}
        reopt_inputs_district[:ExistingBoiler][:fuel_cost_per_mmbtu] = 13.5

        # GHP inputs
        reopt_inputs_district[:GHP] = {}  
        reopt_inputs_district[:GHP][:require_ghp_purchase] = 1
        reopt_inputs_district[:GHP][:building_sqft] = 0.00001
        reopt_inputs_district[:GHP][:om_cost_per_sqft_year] = 0
        reopt_inputs_district[:GHP][:heatpump_capacity_sizing_factor_on_peak_load] = 1.0
  
        # Add ghpghx outputs
        ghpghx_output = {}
        ghpghx_output[:outputs] = {}
        ghpghx_output[:inputs] = {}

        ghpghx_output[:inputs][:heating_thermal_load_mmbtu_per_hr] = [0]*8760
        ghpghx_output[:inputs][:cooling_thermal_load_ton] = [0] * 8760

        
        # Read GHX sizes from system parameter hash
        ghe_specific_params = system_parameter_hash[:district_system][:fifth_generation][:ghe_parameters][:ghe_specific_params]
        ghe_specific_params.each do |ghe_specific_param|
          if ghe_specific_param[:ghe_id] = ghp_id
            number_of_boreholes = ghe_specific_param[:borehole][:number_of_boreholes]
            length_of_boreholes = ghe_specific_param[:borehole][:length_of_boreholes]
            ghpghx_output[:outputs][:number_of_boreholes] = number_of_boreholes
            # convert meters to feet
            ghpghx_output[:outputs][:length_boreholes_ft] = (length_of_boreholes)*3.28084
          end
        end
        
        if File.exist?(@modelica_csv)

          modelica_data = CSV.read(@modelica_csv, headers: true)

          electrical_power_consumed = modelica_data["electrical_power_consumed"]
          electrical_power_consumed_kw = electrical_power_consumed.map { |e| e.to_f / 1000 }
          # if ghp_id.include?('-')
          #   # Note: For some reason when reading columns, '-' from the column headers are removed, whereas ghp_id has -
          #   ghp_id_formatted = ghp_id.delete('-')
          #   ghp_column = "electrical_power_consumed_#{ghp_id_formatted}".to_sym

          # else
          #   # Note: For some reason when reading columns, '-' from the column headers are removed, whereas ghp_id has -
          #   ghp_column = "electrical_power_consumed_#{ghp_id}".to_sym
          # end

          # # Ensure the column exists
          # unless modelica_data.headers.include?(ghp_column)
          #   puts "Column #{ghp_column} does not exist in the CSV file."
          # end

          # # Access values from the column
          # column_values = modelica_data.by_col[ghp_column]

          # TEMPORARY

          #ghpghx_output[:outputs][:yearly_ghx_pump_electric_consumption_series_kw] ||= electrical_power_consumed_kw
          ghpghx_output[:outputs][:yearly_ghx_pump_electric_consumption_series_kw] ||= [0.00001]*8760
          
          ghpghx_output[:outputs][:yearly_total_electric_consumption_kwh] = 0
          #ghpghx_output[:outputs][:yearly_total_electric_consumption_kwh] = electrical_power_consumed_kw.sum
          # this should be divided by 1000 for kw
          reopt_inputs_district[:ElectricLoad][:loads_kw]||= electrical_power_consumed_kw

        else
          ghpghx_output[:outputs][:yearly_total_electric_consumption_kwh] = 0
        end
        
        
        ghpghx_output[:outputs][:peak_combined_heatpump_thermal_ton] = 0.000000001

        ghpghx_output[:outputs][:heat_pump_configuration] = "WSHP"
        ghpghx_output[:outputs][:yearly_total_electric_consumption_series_kw] = [0] * 8760
        ghpghx_output[:outputs][:yearly_heating_heatpump_electric_consumption_series_kw] = [0] * 8760
        ghpghx_output[:outputs][:yearly_cooling_heatpump_electric_consumption_series_kw] = [0] * 8760
        ghpghx_output[:outputs][:yearly_total_electric_consumption_series_kw] = [0] * 8760

        ghpghx_output_all = [ghpghx_output, ghpghx_output]
        reopt_inputs_district[:GHP][:ghpghx_responses] = ghpghx_output_all

        #save output report in reopt_ghp directory
        reopt_ghp_dir = File.join(run_dir, "reopt_ghp", "reopt_ghp_inputs")
        json_file_path = File.join(reopt_ghp_dir, "GHX_#{ghp_id}.json")
        pretty_json = JSON.pretty_generate(reopt_inputs_district)
        File.write(json_file_path, pretty_json)
      end

    end
  end
end
