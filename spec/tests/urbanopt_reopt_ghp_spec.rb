# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************
require_relative '../spec_helper'
require_relative '../../developer_nrel_key'
require 'json-schema'


RSpec.describe URBANopt::REopt do
    
    run_dir = Pathname(__FILE__).dirname.parent / 'run' / 'baseline_scenario_ghe'
    reopt_input_dir = File.join(run_dir, 'reopt_ghp', 'reopt_ghp_inputs')
    reopt_ghp_output = File.join(run_dir, 'reopt_ghp', 'reopt_ghp_outputs')

    modelica_result = Pathname(__FILE__).dirname.parent / 'files' / 'modelica_4'
    system_parameter =  Pathname(__FILE__).dirname.parent / 'files' / 'system_parameter_1.json'
    reopt_ghp_assumption = File.join(Pathname.new(__FILE__).dirname.parent.parent, 'lib', 'urbanopt', 'reopt', 'reopt_ghp_files', 'reopt_ghp_assumption.json')
    schema =  File.join(Pathname.new(__FILE__).dirname.parent.parent, 'lib', 'urbanopt', 'reopt', 'reopt_schema', 'REopt-GHP-input.json')
    
    before(:all) do
        # Load the JSON data before running the tests
        @building_4_path = File.join(reopt_input_dir, 'GHP_building_4.json')        
        @building_5_path = File.join(reopt_input_dir, 'GHP_building_5.json')
        @ghp_path = File.join(reopt_input_dir, 'GHX_7932a208-dcb6-4d23-a46f-288896eaa1bc.json')
        
    end

    it 'can create an input building and GHP reports' do

        begin
            FileUtils.rm_rf(scenario_dir / 'reopt_input_dir')
        rescue StandardError
        end
        post_processor = URBANopt::REopt::REoptGHPPostProcessor.new(run_dir, system_parameter, modelica_result, reopt_ghp_assumption, DEVELOPER_NREL_KEY, localhost=false)
        post_processor.run_reopt_lcca(run_dir)
        # output folder exist
        expect(Dir.exist?(File.join(reopt_input_dir)))

        # expect building file exisits
        expect(File.exist?(File.join(reopt_input_dir, 'GHP_building_4.json')))
        expect(File.exist?(File.join(reopt_input_dir, 'GHP_building_5.json')))
        
        # expect ghp file exists
        expect(File.exist?(File.join(reopt_input_dir, 'GHX_7932a208-dcb6-4d23-a46f-288896eaa1bc.json')))
    end

    it 'can validate the REopt input files' do

        building_4_data = JSON.parse(File.read(@building_4_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, building_4_data)
        expect(validation_errors).to be_empty

        building_5_data = JSON.parse(File.read(@building_5_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, building_5_data)
        expect(validation_errors).to be_empty

        ghp_data = JSON.parse(File.read(@ghp_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, ghp_data)
        expect(validation_errors).to be_empty

    end

    it 'contains data objects as expected' do
        building_4_data = JSON.parse(File.read(@building_4_path), symbolize_names: true)

        expect(building_4_data[:Site][:latitude]).to_not be_nil
        expect(building_4_data[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour]).to_not be_empty
        expect(building_4_data[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour].size).to eq(8760)
        expect(building_4_data[:ElectricTariff][:urdb_label]).to_not be_nil
        
        ghp_data = JSON.parse(File.read(@ghp_path), symbolize_names: true)
        expect(ghp_data[:GHP][:ghpghx_responses][0][:outputs][:yearly_ghx_pump_electric_consumption_series_kw]).to_not be_empty
        expect(ghp_data[:GHP][:ghpghx_responses][0][:outputs][:yearly_ghx_pump_electric_consumption_series_kw].size).to eq(8760)
    end

    it 'can connect to the REopt API' do
        

        # #call the REopt API

        # building_4_data = JSON.parse(File.read(@building_4_path), symbolize_names: true)
        # reopt_output_file = File.join(reopt_ghp_output, "GHP_building_4_output.json")

        # api = URBANopt::REopt::REoptLiteGHPAPI.new(building_4_data, DEVELOPER_NREL_KEY, reopt_output_file, @localhost)
        # # Act
        # ok = api.check_connection(building_4_data)

        # # Assert
        # expect(ok).to be true
    end

    it 'can generate output as expected' do
    end

end