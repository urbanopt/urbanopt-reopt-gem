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

      def create_reopt_input_building(building_ids, run_dir, scenario_report, feature_report, system_parameter_hash, reopt_ghp_assumptions_hash, modelica_result)

        if !reopt_ghp_assumptions_hash.nil?
          reopt_inputs = reopt_ghp_assumptions_hash
        else
          @@logger.info('Using default REopt assumptions')
          # create a dictionary for REopt Inputs
          reopt_inputs = {
            Site: {},
            SpaceHeatingLoad: {},
            DomesticHotWaterLoad: {},
            ElectricLoad: {},
            ElectricTariff: {},
            GHP: {},
            ExistingBoiler: {}
          }
        end


        # # Check scenario report has site data
        # requireds_names = ['latitude', 'longitude']
        # requireds = [scenario_report.location.latitude_deg, scenario_report.location.longitude_deg]
        # puts requireds

        # read system parameter hash
        ghe_specific_param = system_parameter_hash[:district_system][:fifth_generation][:ghe_parameters][:ghe_specific_params]
        ghe_specific_param.each do |ghe|
          number_of_boreholes = ghe[:borehole][:number_of_boreholes]
          length_of_boreholes = ghe[:borehole][:length_of_boreholes]
        end

        # read feature json and csv report
        building_ids.each do |building_id|
          building_json_path = File.join(run_dir, building_id, "feature_reports", "default_feature_report.json")
          puts building_json_path
          
          if File.exist?(building_json_path)
            File.open(building_json_path, 'r') do |file|
              building_json_data = JSON.parse(file.read, symbolize_names: true)
              # update site location. TODO: this should happen outside this loop
              reopt_inputs[:Site][:latitude] = building_json_data[:location][:latitude_deg]
              reopt_inputs[:Site][:longitude] = building_json_data[:location][:longitude_deg]

              reopt_inputs[:GHP][:building_sqft] = building_json_data[:program][:floor_area_sqft]

            end
           
          else
            puts "File not found: #{building_json_path}"
          end
          

          building_csv_path =  File.join(run_dir, building_id, "feature_reports", "default_feature_report.csv")
          # Check if CSV file exists before attempting to read it
          if File.exist?(building_csv_path)
            building_csv_data = CSV.read(building_csv_path, headers: true)
            # Process the CSV data as needed
          else
            puts "CSV file not found: #{building_csv_path}"
          end
        end

        # read_modelica_result

      end

      def create_reopt_input_district(scenario_report, feature_report, system_parameter_hash, reopt_ghp_assumptions_hash, modelica_result)
        #TODO 
      end

    end
  end
end
