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
    nrel_developer_key = DEVELOPER_NREL_KEY

    @run_id = nil
    
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

    it 'can connect to the REopt API and generate UUID' do
        
        reopt_input_file_path = File.join(reopt_input_dir, 'GHP_building_4.json')
        reopt_input_data = nil
        File.open(reopt_input_file_path, 'r') do |f|
            reopt_input_data = JSON.parse(f.read)
        end
        post_url = "https://developer.nrel.gov/api/reopt/stable/job/?api_key=#{nrel_developer_key}"

        # Parse the URL and prepare the HTTP request
        uri = URI.parse(post_url)
        request = Net::HTTP::Post.new(uri)
        request.content_type = 'application/json'

        # Add the JSON payload (assuming 'post' is the body data)
        request.body = reopt_input_data.to_json

        # Send the HTTP request
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
            http.request(request)
        end


        expect(response).to be_a(Net::HTTPSuccess) 
        run_id_dict = JSON.parse(response.body)
        @run_id = run_id_dict['run_uuid']

        expect(@run_id).not_to be_nil
    end

    it 'generates outputs as expected' do

        output_building_4 = File.join(reopt_ghp_output, 'GHP_building_4_output.json')
        output_building_4_data = nil
        File.open(output_building_4, 'r') do |f|
            output_building_4_data = JSON.parse(f.read, symbolize_names: true)
            expect(output_building_4_data[:outputs][:Financial][:npv]).to_not be_nil
            expect(output_building_4_data[:outputs][:Financial][:lcc]).to_not be_nil            
        end
    end

end