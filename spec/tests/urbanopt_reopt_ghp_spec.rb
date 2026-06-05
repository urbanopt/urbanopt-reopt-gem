# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Energy Innovation, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require_relative '../spec_helper'
require_relative '../../developer_api_key'
require 'json-schema'
require 'tmpdir'


RSpec.describe URBANopt::REopt do
    run_dir = Pathname(__FILE__).dirname.parent / 'files' / 'run' / 'baseline_scenario_ghe'
    spec_files_dir = Pathname(__FILE__).dirname.parent / 'files'
    modelica_result = spec_files_dir / 'modelica_4'
    system_parameter =  spec_files_dir / 'system_parameter_1.json'
    source_lib = Pathname(__FILE__).dirname.parent.parent / 'lib'
    reopt_ghp_assumption = source_lib / 'urbanopt' / 'reopt' / 'reopt_ghp_files' / 'reopt_ghp_assumption.json'

    reopt_ghp = run_dir / 'reopt_ghp'
    reopt_input_dir = run_dir / 'reopt_ghp' / 'reopt_ghp_inputs'
    reopt_ghp_output = run_dir / 'reopt_ghp' / 'reopt_ghp_outputs'

    @run_id = nil
    before(:all) do
        # Load the JSON data before running the tests
        @building_4_path = reopt_input_dir / 'GHP_building_4.json'
        @building_5_path = reopt_input_dir / 'GHP_building_5.json'
        @ghp_path = reopt_input_dir / 'GHX_7932a208-dcb6-4d23-a46f-288896eaa1bc.json'
        # Load the BAU JSON data before running the tests
        @building_BAU_4_path = reopt_input_dir / 'BAU_building_4.json'
        @building_BAU_5_path = reopt_input_dir / 'BAU_building_5.json'
    end

    it 'can create an input building and GHP reports' do
        begin
            FileUtils.rm_rf(run_dir / 'reopt_ghp')
        rescue StandardError
        end
        post_processor = URBANopt::REopt::REoptGHPPostProcessor.new(run_dir, system_parameter, modelica_result, reopt_ghp_assumption, DEVELOPER_API_KEY)
        post_processor.run_reopt_lcca()
        # output folder exist
        expect(reopt_input_dir.directory?)

        # expect building file exists
        expect((reopt_input_dir / 'GHP_building_4.json').file?)
        expect((reopt_input_dir / 'GHP_building_5.json').file?)

        # expect ghp file exists
        expect((reopt_input_dir / 'GHX_7932a208-dcb6-4d23-a46f-288896eaa1bc.json').file?)
    end

    it 'can validate the REopt GHP input files' do
        schema_path = source_lib / 'urbanopt' / 'reopt' / 'reopt_schema' / 'REopt-GHP-input.json'
        schema =  JSON.parse(File.read(schema_path))

        building_4_data = JSON.parse(File.read(@building_4_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, building_4_data)
        if validation_errors.any?
            puts "Validation errors for building_4_data:"
            validation_errors.each { |err| puts "- #{err}" }
        end
        
        expect(validation_errors).to be_empty

        building_5_data = JSON.parse(File.read(@building_5_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, building_5_data)
        expect(validation_errors).to be_empty

        ghp_data = JSON.parse(File.read(@ghp_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, ghp_data)
        expect(validation_errors).to be_empty

    end

    it 'can validate the REopt BAU input files' do
        schema_path = source_lib / 'urbanopt' / 'reopt' / 'reopt_schema' / 'REopt-BAU-input.json'
        schema =  JSON.parse(File.read(schema_path))

        building_4_BAU_data = JSON.parse(File.read(@building_BAU_4_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, building_4_BAU_data)
        expect(validation_errors).to be_empty

        building_5_BAU_data = JSON.parse(File.read(@building_BAU_5_path), symbolize_names: true)
        validation_errors = JSON::Validator.fully_validate(schema, building_5_BAU_data)
        expect(validation_errors).to be_empty

    end

    it 'contains data objects as expected' do
        building_4_data = JSON.parse(File.read(@building_4_path), symbolize_names: true)

        expect(building_4_data[:Site][:latitude]).to_not be_nil
        expect(building_4_data[:ElectricLoad][:year]).to_not be_nil
        expect(building_4_data[:ElectricLoad][:loads_kw]).to_not be_empty
        expect(building_4_data[:ElectricLoad][:loads_kw].size).to eq(8760)
        expect(building_4_data[:ElectricTariff][:urdb_label]).to_not be_nil

        ghp_data = JSON.parse(File.read(@ghp_path), symbolize_names: true)
        expect(ghp_data[:GHP][:ghpghx_responses][0][:outputs][:yearly_ghx_pump_electric_consumption_series_kw]).to_not be_empty
        expect(ghp_data[:GHP][:ghpghx_responses][0][:outputs][:yearly_ghx_pump_electric_consumption_series_kw].size).to eq(8760)
    end

        it 'aggregates 15-minute heating and dhw series to hourly 8760 values' do
                system_parameter_hash = JSON.parse(File.read(system_parameter), symbolize_names: true)
                assumptions_hash = JSON.parse(File.read(reopt_ghp_assumption), symbolize_names: true)
                adapter = URBANopt::REopt::REoptGHPAdapter.new

                Dir.mktmpdir('reopt_ghp_subhourly_') do |tmp_run_dir|
                        building_id = 4
                        feature_reports_dir = File.join(tmp_run_dir, building_id.to_s, 'feature_reports')
                        FileUtils.mkdir_p(feature_reports_dir)
                        FileUtils.mkdir_p(File.join(tmp_run_dir, 'reopt_ghp', 'reopt_ghp_inputs'))

                        # Minimal scenario report for site location fields used by create_reopt_input_building_ghp
                        scenario_report = {
                            scenario_report: {
                                location: {
                                    latitude_deg: 39.742,
                                    longitude_deg: -104.991
                                }
                            }
                        }
                        File.write(File.join(tmp_run_dir, 'default_scenario_report.json'), JSON.pretty_generate(scenario_report))

                        # Build a 15-minute (35040 row) CSV with constant 1.0 kBtu/timestep loads.
                        # Expected aggregated hourly value is 4.0 kBtu/h => 0.004 mmbtu/h.
                        csv_path = File.join(feature_reports_dir, 'default_feature_report.csv')
                        CSV.open(csv_path, 'w') do |csv|
                                csv << ['Heating:NaturalGas(kBtu)', 'WaterSystems:NaturalGas(kBtu)']
                                35_040.times { csv << [1.0, 1.0] }
                        end

                        # Minimal feature report JSON for optional building_sqft lookup in GHP block.
                        feature_report_json = {
                            program: {
                                footprint_area_sqft: 1000.0
                            }
                        }
                        File.write(File.join(feature_reports_dir, 'default_feature_report.json'), JSON.pretty_generate(feature_report_json))

                        adapter.create_reopt_input_building_ghp(tmp_run_dir, system_parameter_hash, assumptions_hash, building_id, modelica_result)

                        out_path = File.join(tmp_run_dir, 'reopt_ghp', 'reopt_ghp_inputs', "GHP_building_#{building_id}.json")
                        output = JSON.parse(File.read(out_path), symbolize_names: true)

                        heating_series = output[:SpaceHeatingLoad][:fuel_loads_mmbtu_per_hour]
                        dhw_series = output[:DomesticHotWaterLoad][:fuel_loads_mmbtu_per_hour]

                        expect(heating_series.size).to eq(8760)
                        expect(dhw_series.size).to eq(8760)
                        expect(heating_series.uniq).to eq([0.004])
                        expect(dhw_series.uniq).to eq([0.004])
                end
        end

    it 'can connect to the REopt API and generate UUID' do

        reopt_input_file_path = reopt_input_dir / 'GHP_building_4.json'
        reopt_input_data = nil
        File.open(reopt_input_file_path, 'r') do |f|
            reopt_input_data = JSON.parse(f.read)
        end
        post_url = "https://developer.nlr.gov/api/reopt/v3/job/?api_key=#{DEVELOPER_API_KEY}"

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
            next if file == '.' || file == '..'
            file_path = reopt_ghp_output / file
            next unless File.file?(file_path)

            File.open(file_path, 'r') do |f|
                file_data = JSON.parse(f.read, symbolize_names: true)
                expect(file_data[:outputs][:Financial][:npv]).to_not be_nil
                expect(file_data[:outputs][:Financial][:lcc]).to_not be_nil
                expect(file_data[:messages][:errors]).to be_nil.or be_empty
            end
        end
    end

    it 'generates a non-empty LCCA summary for BAU and GHP' do
        summary_path = reopt_ghp / 'reopt_ghp_result_summary.json'
        expect(summary_path.file?).to be true

        summary = JSON.parse(File.read(summary_path), symbolize_names: true)
        expect(summary).to_not be_empty

        expect(summary[:lcc][:lcc_net]).to_not be_nil
        expect(summary[:lifecycle_capital_cost][:ghp_total]).to_not be_nil
        expect(summary[:npv][:net]).to_not be_nil
        expect(summary[:lifecycle_elecbill_after_tax].keys).to include(:bau_total, :ghp_total)
    end


end
