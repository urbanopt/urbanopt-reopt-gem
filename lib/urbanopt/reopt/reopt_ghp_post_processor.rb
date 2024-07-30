# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'bundler/setup'
require 'urbanopt/reporting/default_reports'
require 'urbanopt/reopt/reopt_logger'
require 'csv'
require 'json'


module URBANopt # :nodoc:
  module REopt # :nodoc:
    class REoptGHPPostProcessor

      def initialize(building_ids, run_dir, scenario_report, feature_report, system_parameter, modelica_result, reopt_ghp_assumptions = nil, nrel_developer_key = nil, localhost = false)
        # initialize @@logger
        @@logger ||= URBANopt::REopt.reopt_logger

        @nrel_developer_key = nrel_developer_key
        @localhost = localhost
        @reopt_ghp_output_district = nil
        @reopt_ghp_output_building = []
        @reopt_ghp_assumptions_hash = nil
        @reopt_ghp_assumptions = nil
        @reopt_ghp_assumptions_hash = nil
        @system_parameter = nil
        @system_parameter_hash = nil
        @modelica_result = nil
        @building_ids = nil
        @run_dir = nil


        # if !scenario_report.nil?
        #     @scenario_report = scenario_report
            
        #     # create a reopt ghp lcca results folder
        #     if !Dir.exist?(File.join(@scenario_report.directory_name, 'reopt_ghp_result'))
        #       Dir.mkdir(File.join(@scenario_report.directory_name, 'reopt_ghp_result'))
        #       @@logger.info("Created directory: #{File.join(@scenario_report.directory_name, 'reopt_ghp_result')}")
        #     end
            
        #     # GHP result JSON file stored at the district level 
        #     @reopt_ghp_input_district = File.join(@scenario_report.directory_name, "reopt_ghp_result/reopt_ghp_input_#{@scenario_report.id}.json")
        #     # TO DO FIX THIS

        # end

        # if !feature_report.nil?
        #   # This is an array of feature reports
        #   @feature_report = feature_report

        #   @feature_report.each do |fr|
        #     # REopt GHP input at building level
        #     @reopt_ghp_output_district = File.join(@scenario_report.directory_name, "reopt_ghp_result/reopt_ghp_output_#{@scenario_report.id}.json")
        #   end
        # end

        if !reopt_ghp_assumptions.nil?
          @reopt_ghp_assumptions = reopt_ghp_assumptions
          File.open(reopt_ghp_assumptions, 'r') do |file|
            @reopt_ghp_assumptions_hash = JSON.parse(file.read, symbolize_names: true)
          end
        end

        if !system_parameter.nil?
          @system_parameter = system_parameter
          File.open(system_parameter, 'r') do |file|
            @system_parameter_hash = JSON.parse(file.read, symbolize_names: true)
          end
        end

        if !modelica_result.nil?
          @modelica_result = modelica_result
        end
      end

      attr_accessor :building_ids, :run_dir, :scenario_report, :feature_report, :system_parameter_hash, :reopt_ghp_assumptions_hash, :modelica_result, :reopt_ghp_output

  
      # # Create REopt input and output building report
      # #todo : CHECK IF OUTPUT FILE NAME NEEDS TO BE ADDED IN ARGS, OR COLON AFTER REPORT VARIABLES
      def run_reopt_lcca_building(building_ids, run_dir, scenario_report, feature_report, reopt_ghp_assumptions: nil, modelica_result: nil, reopt_output_file: nil)
        api = URBANopt::REopt::REoptLiteAPI.new(@nrel_developer_key, @localhost)
        adapter = URBANopt::REopt::REoptGHPAdapter.new
        
        # create REopt building input file
        reopt_input_building = adapter.create_reopt_input_building(building_ids, run_dir, scenario_report, feature_report, system_parameter_hash, reopt_ghp_assumptions_hash, modelica_result)

        # create REopt district input file
        reopt_input_district =  adapter.create_reopt_input_district(scenario_report, feature_report, system_parameter_hash, reopt_ghp_assumptions_hash, modelica_result)
        
        # if reopt_output_file.nil?
        # #reopt_output_file = File.join(scenario_report.directory_name, 'reopt_ghp')
        # end
        
        # reopt_output = api.reopt_request(reopt_input, reopt_output_file)
        # @@logger.debug("REOpt output file: #{reopt_output_file}")

        # result = adapter.update_feature_report(feature_report, reopt_output, timeseries_csv_path, resilience_stats)
        
        # if !save_name.nil?
        # result.save save_name
        # end
        
        #return result
      end

      # # Create REopt input and output district report

    
    end #REoptGHPPostProcessor
  end #REopt
end #URBANopt