# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************
require_relative '../spec_helper'
require_relative '../../developer_nrel_key'
require 'json-schema'


RSpec.describe URBANopt::REopt do
    run_dir = Pathname(__FILE__).dirname.parent / 'files' / 'run' / 'baseline_scenario_ghe'
    spec_files_dir = Pathname(__FILE__).dirname.parent / 'files'
    modelica_result = spec_files_dir / 'modelica_4'
    system_parameter =  spec_files_dir / 'system_parameter_1.json'
    source_lib = Pathname(__FILE__).dirname.parent.parent / 'lib'
    reopt_ghp_assumption = source_lib / 'urbanopt' / 'reopt' / 'reopt_ghp_files' / 'reopt_ghp_assumption.json'

    reopt_input_dir = run_dir / 'reopt_ghp' / 'reopt_ghp_inputs'
    reopt_ghp_output = run_dir / 'reopt_ghp' / 'reopt_ghp_outputs'

    @run_id = nil
    before(:all) do
        # Load the JSON data before running the tests
        @building_4_path = reopt_input_dir / 'GHP_building_4.json'
        @building_5_path = reopt_input_dir / 'GHP_building_5.json'
        @ghp_path = reopt_input_dir / 'GHX_7932a208-dcb6-4d23-a46f-288896eaa1bc.json'

    end

    it 'can create an input building and GHP reports' do
        begin
            FileUtils.rm_rf(run_dir / 'reopt_ghp')
        rescue StandardError
        end
        post_processor = URBANopt::REopt::REoptGHPPostProcessor.new(run_dir, system_parameter, modelica_result, reopt_ghp_assumption, DEVELOPER_NREL_KEY, localhost=false)
        post_processor.run_reopt_lcca()
        # output folder exist
        expect(reopt_input_dir.directory?)

        # expect building file exists
        expect((reopt_input_dir / 'GHP_building_4.json').file?)
        expect((reopt_input_dir / 'GHP_building_5.json').file?)

        # expect ghp file exists
        expect((reopt_input_dir / 'GHX_7932a208-dcb6-4d23-a46f-288896eaa1bc.json').file?)
    end

    it 'can validate the REopt input files' do
        schema_path = source_lib / 'urbanopt' / 'reopt' / 'reopt_schema' / 'REopt-GHP-input.json'
        schema =  JSON.parse(File.read(schema_path))

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
        expect(building_4_data[:ElectricLoad][:loads_kw].to_not be_empty
        expect(building_4_data[:ElectricLoad][:loads_kw].size).to eq(8760)
        expect(building_4_data[:ElectricTariff][:urdb_label]).to_not be_nil

        ghp_data = JSON.parse(File.read(@ghp_path), symbolize_names: true)
        expect(ghp_data[:GHP][:ghpghx_responses][0][:outputs][:yearly_ghx_pump_electric_consumption_series_kw]).to_not be_empty
        expect(ghp_data[:GHP][:ghpghx_responses][0][:outputs][:yearly_ghx_pump_electric_consumption_series_kw].size).to eq(8760)
    end

    it 'can connect to the REopt API and generate UUID' do

        reopt_input_file_path = reopt_input_dir / 'GHP_building_4.json'
        reopt_input_data = nil
        File.open(reopt_input_file_path, 'r') do |f|
            reopt_input_data = JSON.parse(f.read)
        end
        post_url = "https://developer.nrel.gov/api/reopt/stable/job/?api_key=#{DEVELOPER_NREL_KEY}"

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

        Dir.foreach(reopt_ghp_output) do |file|
            next if file == '.' || file == '..' # Skip current and parent directory references
            file_path = reopt_ghp_output / file

            if File.file?(file_path)
                File.open(file_path, 'r') do |f|
                    file_data = JSON.parse(f.read, symbolize_names: true)
                    expect(file_data[:outputs][:Financial][:npv]).to_not be_nil
                    expect(file_data[:outputs][:Financial][:lcc]).to_not be_nil
                    expect(file_data[:messages][:errors]).to be_nil.or be_empty
                end
            end
        end
    end

end
