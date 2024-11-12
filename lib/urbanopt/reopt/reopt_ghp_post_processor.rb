# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require 'bundler/setup'
require 'urbanopt/reopt/reopt_logger'
require 'urbanopt/reopt/reopt_ghp_api'
require 'csv'
require 'json'
require 'fileutils'

module URBANopt # :nodoc:
  module REopt # :nodoc:
    class REoptGHPPostProcessor

      def initialize(run_dir, system_parameter, modelica_result, reopt_ghp_assumptions = nil, nrel_developer_key = nil, localhost)
        # initialize @@logger
        @@logger ||= URBANopt::REopt.reopt_logger

        @nrel_developer_key = nrel_developer_key
        @localhost = localhost
        @reopt_ghp_output_district = nil
        @reopt_ghp_output_building = []
        @reopt_ghp_assumptions_hash = nil
        @reopt_ghp_assumptions = nil
        @system_parameter = nil
        @system_parameter_hash = nil
        @modelica_result = nil
        @building_ids = nil
        @run_dir = run_dir

        if !reopt_ghp_assumptions.nil?
          @reopt_ghp_assumptions = reopt_ghp_assumptions
          File.open(reopt_ghp_assumptions, 'r') do |file|
            @reopt_ghp_assumptions_input_hash = JSON.parse(file.read, symbolize_names: true)
          end
        end

        if !system_parameter.nil?
          @system_parameter = system_parameter
          File.open(system_parameter, 'r') do |file|
            @system_parameter_input_hash = JSON.parse(file.read, symbolize_names: true)
          end
          #Determine loop order
          loop_order = File.join(File.dirname(system_parameter), '_loop_order.json')
          if File.exist?(loop_order)
            File.open(loop_order, 'r') do |file|
              loop_order_input= JSON.parse(file.read, symbolize_names: true)
              # Check the type of the parsed data
              if loop_order_input.is_a?(Array)
                @loop_order_input_hash = loop_order_input
                @loop_order_input_hash.each do |item|
                  puts "Building IDs in group: #{item[:list_bldg_ids_in_group].inspect}"
                  puts "GHE IDs in group: #{item[:list_ghe_ids_in_group].inspect}"
                end
              elsif loop_order_input.is_a?(Hash)
                @loop_order_input_hash = [loop_order_input] # Wrap in array if a single object
                @loop_order_input_hash.each do |item|
                  puts "Building IDs in group: #{item[:list_bldg_ids_in_group].inspect}"
                  puts "GHE IDs in group: #{item[:list_ghe_ids_in_group].inspect}"
                end
              else
                puts "Unexpected JSON structure"
              end
            end
          end

        end

        if !modelica_result.nil?
          @modelica_result_input = modelica_result
        end
      end

      attr_accessor :run_dir, :system_parameter_input_hash, :reopt_ghp_assumptions_input_hash, :loop_order_input_hash, :modelica_result_input

      # # Create REopt input and output building report
      def run_reopt_lcca(system_parameter_hash: nil, reopt_ghp_assumptions_hash: nil, modelica_result: nil)

        adapter = URBANopt::REopt::REoptGHPAdapter.new

        # if these arguments are specified, use them
        if !system_parameter_hash.nil?
          @system_parameter_input_hash = system_parameter_hash
        end

        if !reopt_ghp_assumptions_hash.nil?
          @reopt_ghp_assumptions_input_hash = reopt_ghp_assumptions_hash
        end


        if !modelica_result.nil?
          @modelica_result_input = modelica_result
        end

        # Create folder for REopt input files only if they dont exist
        reopt_ghp_dir = File.join(@run_dir, "reopt_ghp")
        reopt_ghp_input = File.join(reopt_ghp_dir, "reopt_ghp_inputs")
        unless Dir.exist?(reopt_ghp_dir)
          FileUtils.mkdir_p(reopt_ghp_dir)
        end
        unless Dir.exist?(reopt_ghp_input)
          FileUtils.mkdir_p(reopt_ghp_input)
        end

        reopt_ghp_output = File.join(reopt_ghp_dir, "reopt_ghp_outputs")
        unless Dir.exist?(reopt_ghp_output)
          FileUtils.mkdir_p(reopt_ghp_output)
        end

        # get building IDs from _loop_order.json
        building_ids = []
        ghp_ids = []
        @loop_order_input_hash.each do |loop|
          building_ids.concat(loop[:list_bldg_ids_in_group].flatten)
          ghp_ids.concat(loop[:list_ghe_ids_in_group].flatten)
        end

        building_ids.each do |building_id|
          # create REopt building input file for all buildings in loop order list
          reopt_input_building = adapter.create_reopt_input_building(@run_dir, @system_parameter_input_hash, @reopt_ghp_assumptions_input_hash, building_id, @modelica_result_input)
        end
        ghp_ids.each do |ghp_id|
          # create REopt district input file
          reopt_input_district = adapter.create_reopt_input_district(@run_dir, @system_parameter_input_hash, @reopt_ghp_assumptions_input_hash, ghp_id, @modelica_result_input)
        end

        Dir.foreach(reopt_ghp_input) do |input_file|
          # Skip '.' and '..' (current and parent directory entries)
          next if input_file == '.' || input_file == '..'

          reopt_ghp_input_file_path = File.join(reopt_ghp_input, input_file)

          reopt_input_data = nil

          File.open(reopt_ghp_input_file_path, 'r') do |f|
            reopt_input_data = JSON.parse(f.read)
          end

          base_name = File.basename(input_file, '.json')

          # reopt_ghp_output_file
          reopt_output_file = File.join(reopt_ghp_output, "#{base_name}_output.json")
          #call the REopt API
          api = URBANopt::REopt::REoptLiteGHPAPI.new(reopt_input_data, DEVELOPER_NREL_KEY, reopt_output_file, @localhost)
          api.get_api_results()

        end

      end

    end #REoptGHPPostProcessor
  end #REopt
end #URBANopt
