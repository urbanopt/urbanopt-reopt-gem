# *********************************************************************************
# URBANopt (tm), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://github.com/urbanopt/urbanopt-reopt-gem/blob/develop/LICENSE.md
# *********************************************************************************

require_relative '../spec_helper'
require_relative '../../developer_nrel_key'

RSpec.describe URBANopt::REopt do
  scenario_dir = Pathname(__FILE__).dirname.parent / 'run' / 'example_scenario'
  spec_files_dir = Pathname(__FILE__).dirname.parent / 'files'
  feature_list = (1..2)

  it 'has a version number' do
    expect(URBANopt::REopt::VERSION).not_to be nil
  end

  it 'can connect to reopt' do
    # Set up
    api = URBANopt::REopt::REoptLiteAPI.new(DEVELOPER_NREL_KEY, false)
    dummy_data = { Site: { latitude: 40, longitude: -110}, ElectricTariff: { urdb_label: '594976725457a37b1175d089' }, ElectricLoad: { doe_reference_name: 'Hospital', annual_kwh: 1000000 } }

    # Act
    ok = api.check_connection(dummy_data)

    # Assert
    expect(ok).to be true
  end

  it 'returns graceful status code message to user' do
    # Set up
    bogus_dev_key = "#{DEVELOPER_NREL_KEY}asdf"
    api = URBANopt::REopt::REoptLiteAPI.new(bogus_dev_key, false)

    header = { 'Content-Type' => 'application/json' }
    @uri_submit = URI.parse("https://developer.nrel.gov/api/reopt/v2/job?api_key=#{@bogus_dev_key}")
    http = Net::HTTP.new(@uri_submit.host, @uri_submit.port)
    http.use_ssl = true

    # Build the request
    post_request = Net::HTTP::Post.new(@uri_submit, header)
    dummy_data = { Site: { latitude: 40, longitude: -110}, ElectricTariff: { urdb_label: '594976725457a37b1175d089' }, ElectricLoad: { doe_reference_name: 'Hospital', annual_kwh: 1000000 } }
    post_request.body = ::JSON.generate(dummy_data, allow_nan: true)

    # Act, Assert
    expect { api.make_request(http, post_request) }
      .to output(a_string_including('REopt has returned'))
      .to_stdout_from_any_process
  end

  it 'can process a scenario report' do
    # Set up
    begin
      FileUtils.rm_rf(scenario_dir / 'test__')
    rescue StandardError
    end
    begin
      FileUtils.rm_rf(scenario_dir / 'reopt')
    rescue StandardError
    end
    if !File.directory? scenario_dir / 'test__'
      Dir.mkdir(scenario_dir / 'test__')
    end

    scenario_report = URBANopt::Reporting::DefaultReports::ScenarioReport.new
    scenario_report.directory_name = scenario_dir

    feature_list.each do |feature_id|
      feature_reports_path = scenario_dir / feature_id.to_s / '007_default_feature_reports' / 'default_feature_reports.json'

      expect(File.exist?(feature_reports_path)).to be true

      feature_reports_json = nil
      File.open(feature_reports_path, 'r') do |file|
        feature_reports_json = JSON.parse(file.read, symbolize_names: true)
      end

      feature_report = URBANopt::Reporting::DefaultReports::FeatureReport.new(feature_reports_json)

      feature_report_dir = scenario_dir / feature_id.to_s
      feature_report.directory_name = feature_report_dir
      feature_report.timeseries_csv.path = scenario_dir / '1' / '007_default_feature_reports' / 'default_feature_reports.csv'
      scenario_report.add_feature_report(feature_report)
    end
    scenario_report.save 'test__/can_process_a_scenario_report'

    # Assume that file size over 20kb means data was written correctly
    expect((File.size(scenario_dir / 'test__' / 'can_process_a_scenario_report.json').to_f / 1024) > 20)

    reopt_assumptions_file = spec_files_dir / 'reopt_assumptions_with_wind_v3.json'

    # Act
    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(scenario_report, reopt_assumptions_file, nil, DEVELOPER_NREL_KEY)
    scenario_report = reopt_post_processor.run_scenario_report(scenario_report: scenario_report, save_name: 'test__/scenario_report_reopt_global')
    # Resilience functionality is not yet implemented with REopt v3
    # resilience_scenario_report = reopt_post_processor.run_scenario_report(scenario_report: scenario_report, run_resilience: true, save_name: 'test__/scenario_report_reopt_resilience')

    # Assert
    # Assume that file size over 20kb means data was written correctly. Test file is expected to be about 29kb
    expect((File.size(scenario_dir / 'test__' / 'scenario_report_reopt_global.json').to_f / 1024) > 20)
    # expect((File.size(scenario_dir / 'test__' / 'scenario_report_reopt_resilience.json').to_f / 1024) > 20)

    # Cleanup
    FileUtils.rm_rf(scenario_dir / 'test__')
    FileUtils.rm_rf(scenario_dir / 'reopt')
    FileUtils.rm_rf(scenario_dir / '1' / 'feature_reports')
    FileUtils.rm_rf(scenario_dir / '2' / 'feature_reports')
  end

  it 'can process a feature report and handle time resolution conversion' do
    # Set up
    begin
      FileUtils.rm_rf(scenario_dir / 'test__')
    rescue StandardError
    end
    begin
      FileUtils.rm_rf(scenario_dir / '1' / 'reopt')
    rescue StandardError
    end
    if !File.directory? scenario_dir / 'test__'
      Dir.mkdir(scenario_dir / 'test__')
    end
    feature_reports_path = scenario_dir / '1' / '007_default_feature_reports' / 'default_feature_reports.json'

    expect(File.exist?(feature_reports_path)).to be true

    feature_reports_json = nil
    File.open(feature_reports_path, 'r') do |file|
      feature_reports_json = JSON.parse(file.read, symbolize_names: true)
    end

    feature_report = URBANopt::Reporting::DefaultReports::FeatureReport.new(feature_reports_json)

    feature_report_dir = scenario_dir / '1'
    Dir.mkdir(scenario_dir / '1' / 'reopt')
    feature_report.directory_name = feature_report_dir
    feature_report.timeseries_csv.path = scenario_dir / '1' / '007_default_feature_reports' / 'default_feature_reports.csv'

    reopt_output_file = feature_report_dir / 'reopt' / 'feature_report_reopt_run1.json'
    timeseries_output_file = feature_report_dir / 'feature_report_timeseries1.csv'
    reopt_assumptions_file = spec_files_dir / 'reopt_assumptions_4tsperhour_v3.json'
    reopt_assumptions = nil
    File.open(reopt_assumptions_file, 'r') do |file|
      reopt_assumptions = JSON.parse(file.read, symbolize_names: true)
    end
    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(nil, nil, nil, DEVELOPER_NREL_KEY)

    # Act
    feature_report = reopt_post_processor.run_feature_report(feature_report: feature_report, reopt_assumptions_hash: reopt_assumptions, reopt_output_file: reopt_output_file, timeseries_csv_path: timeseries_output_file, save_name: 'feature_report_reopt1')
    feature_report = reopt_post_processor.run_feature_report(feature_report: feature_report, reopt_assumptions_hash: reopt_assumptions, timeseries_csv_path: timeseries_output_file, save_name: 'feature_report_reopt2')
    feature_report = reopt_post_processor.run_feature_report(feature_report: feature_report, reopt_assumptions_hash: reopt_assumptions, reopt_output_file: reopt_output_file, save_name: 'feature_report_reopt3')

    # Assert
    # Assume that file size over 7kb means data was written correctly. Test file is expected to be about 10kb
    expect((File.size(feature_report_dir / 'feature_reports' / 'feature_report_reopt1.json').to_f / 1024) > 7)
    expect((File.size(feature_report_dir / 'feature_reports' / 'feature_report_reopt2.json').to_f / 1024) > 7)
    expect((File.size(feature_report_dir / 'feature_reports' / 'feature_report_reopt3.json').to_f / 1024) > 7)

    # Cleanup
    FileUtils.rm_rf(scenario_dir / '1' / 'reopt')
    FileUtils.rm_rf(scenario_dir / '1' / 'feature_reports')
  end

  it "can process multiple PV's" do
    # Set up
    begin
      FileUtils.rm_rf(scenario_dir / 'test__')
      FileUtils.rm_rf(scenario_dir / 'reopt')
    rescue StandardError
    end
    if !File.directory? scenario_dir / 'test__'
      Dir.mkdir(scenario_dir / 'test__')
    end
    scenario_report = URBANopt::Reporting::DefaultReports::ScenarioReport.new
    scenario_report.directory_name = scenario_dir

    feature_list.each do |feature_id|
      feature_reports_path = scenario_dir / feature_id.to_s / '007_default_feature_reports' / 'default_feature_reports.json'

      expect(File.exist?(feature_reports_path)).to be true

      feature_reports_json = nil
      File.open(feature_reports_path, 'r') do |file|
        feature_reports_json = JSON.parse(file.read, symbolize_names: true)
      end

      # Act
      feature_report = URBANopt::Reporting::DefaultReports::FeatureReport.new(feature_reports_json)

      feature_report_dir = scenario_dir / feature_id.to_s
      feature_report.directory_name = feature_report_dir
      feature_report.timeseries_csv.path = scenario_dir / feature_id.to_s / '007_default_feature_reports' / 'default_feature_reports.csv'
      scenario_report.add_feature_report(feature_report)
    end

    scenario_report.save 'test__/can_process_multiple_PV'

    # Assert
    # Assume that file size over 20kb means data was written correctly. Test file is expected to be about 29kb
    expect((File.size(scenario_dir / 'test__' / 'can_process_multiple_PV.json').to_f / 1024) > 20)

    # Set up
    reopt_output_file = scenario_dir / 'scenario_report_multiPV_reopt_run.json'
    timeseries_output_file = scenario_dir / 'scenario_report_timeseries1.csv'
    reopt_assumptions_file = spec_files_dir / 'reopt_assumptions_with_wind_v3.json'

    File.open(reopt_assumptions_file, 'r') do |file|
      @scenario_reopt_default_assumptions_hash = JSON.parse(file.read, symbolize_names: true)
    end

    api = URBANopt::REopt::REoptLiteAPI.new(DEVELOPER_NREL_KEY, @localhost)
    adapter = URBANopt::REopt::ScenarioReportAdapter.new

    reopt_input = adapter.reopt_json_from_scenario_report(scenario_report, @scenario_reopt_default_assumptions_hash)
    reopt_input[:PV][:min_kw] = 5

    # Act
    reopt_output = api.reopt_request(reopt_input, reopt_output_file)

    reopt_output['outputs']['PV'] = [reopt_output['outputs']['PV'], reopt_output['outputs']['PV']]

    scenario_report = adapter.update_scenario_report(scenario_report, reopt_output, timeseries_output_file)
    scenario_report.save 'test__/scenario_report_reopt_mulitPV'

    # Assert
    # Assume that file size over 20kb means data was written correctly. Test file is expected to be about 29kb
    expect((File.size(reopt_output_file).to_f / 1024) > 20)

    # Cleanup
    FileUtils.rm_rf(scenario_dir / 'test__')
    FileUtils.rm_rf(scenario_dir / '1' / 'feature_reports')
    FileUtils.rm_rf(scenario_dir / '2' / 'feature_reports')
    FileUtils.rm_rf(scenario_dir / 'scenario_report_multiPV_reopt_run.json')
  end

  it 'can process a set of feature reports' do
    # Set up
    begin
      FileUtils.rm_rf(scenario_dir / '1' / 'reopt')
      FileUtils.rm_rf(scenario_dir / '2' / 'reopt')
      FileUtils.rm_rf(scenario_dir / '1' / 'feature_reports' / '/test__')
    FileUtils.rm_rf(scenario_dir / '2' / 'feature_reports' / '/test__')
    rescue StandardError
    end
    reopt_assumption_files = []
    reopt_assumption_jsons = []
    reopt_assumptions_file = spec_files_dir / 'reopt_assumptions_with_wind_v3.json'
    reopt_assumptions = nil
    feature_reports = []
    reopt_output_files = []
    timeseries_output_files = []
    feature_report_save_names = []
    feature_list.each do |feature_id|
      feature_reports_path = scenario_dir / feature_id.to_s / '007_default_feature_reports' / 'default_feature_reports.json'
      Dir.mkdir(scenario_dir / feature_id.to_s / 'reopt')

      expect((File.size(feature_reports_path).to_f / 1024) > 20)

      feature_reports_json = nil
      File.open(feature_reports_path, 'r') do |file|
        feature_reports_json = JSON.parse(file.read, symbolize_names: true)
      end

      feature_report = URBANopt::Reporting::DefaultReports::FeatureReport.new(feature_reports_json)

      feature_report_dir = scenario_dir / feature_id.to_s
      feature_report.directory_name = feature_report_dir
      feature_report.timeseries_csv.path = scenario_dir / feature_id.to_s / '007_default_feature_reports' / 'default_feature_reports.csv'

      reopt_assumption_files << reopt_assumptions_file
      feature_reports << feature_report
      feature_report_save_names << 'feature_report_reopt'
    end

    # Act
    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(nil, nil, reopt_assumption_files, DEVELOPER_NREL_KEY)
    processed_feature_reports = reopt_post_processor.run_feature_reports(feature_reports: feature_reports, save_names: feature_report_save_names)

    # Assert
    feature_list.each do |feature_id|
      expect((File.size(scenario_dir / feature_id.to_s / 'feature_reports' / 'feature_report_reopt.json').to_f / 1024) > 20)
      expect((File.size(scenario_dir / feature_id.to_s / 'reopt' / "feature_report_#{feature_id}_reopt_run.json").to_f / 1024) > 20)
    end

    # Cleanup
    FileUtils.rm_rf(scenario_dir / '1' / 'reopt')
    FileUtils.rm_rf(scenario_dir / '2' / 'reopt')
    FileUtils.rm_rf(scenario_dir / '1' / 'feature_reports')
    FileUtils.rm_rf(scenario_dir / '2' / 'feature_reports')
  end

  it 'can process all feature reports in a scenario report individually' do
    # Set up
    begin
      FileUtils.rm_rf(scenario_dir / '1' / 'reopt')
      FileUtils.rm_rf(scenario_dir / '2' / 'reopt')
      FileUtils.rm_rf(scenario_dir / '1' / 'feature_reports')
      FileUtils.rm_rf(scenario_dir / '2' / 'feature_reports')
      FileUtils.rm_rf(scenario_dir / 'reopt')
      FileUtils.rm_rf(scenario_dir / 'test__')
    rescue StandardError
    end
    if !File.directory? scenario_dir / 'test__'
      Dir.mkdir(scenario_dir / 'test__')
    end
    scenario_report = URBANopt::Reporting::DefaultReports::ScenarioReport.new
    scenario_report.directory_name = scenario_dir

    reopt_assumption_jsons = []
    reopt_assumptions_file = spec_files_dir / 'reopt_assumptions_with_wind_v3.json'
    reopt_assumptions = nil
    File.open(reopt_assumptions_file, 'r') do |file|
      reopt_assumptions = JSON.parse(file.read, symbolize_names: true)
    end
    reopt_assumption_files = []
    reopt_output_files = []
    feature_report_timeseries_output_files = []
    feature_report_save_names = []

    feature_list.each do |feature_id|
      feature_reports_path = scenario_dir / feature_id.to_s / '007_default_feature_reports' / 'default_feature_reports.json'
      expect(File.exist?(feature_reports_path)).to be true

      feature_reports_json = nil
      File.open(feature_reports_path, 'r') do |file|
        feature_reports_json = JSON.parse(file.read, symbolize_names: true)
      end

      feature_report = URBANopt::Reporting::DefaultReports::FeatureReport.new(feature_reports_json)
      feature_report_dir = scenario_dir / feature_id.to_s
      feature_report.directory_name = feature_report_dir
      feature_report.timeseries_csv.path = scenario_dir / feature_id.to_s / '007_default_feature_reports' / 'default_feature_reports.csv'

      reopt_assumption_files << reopt_assumptions_file
      reopt_assumption_jsons << Marshal.load(Marshal.dump(reopt_assumptions))
      reopt_output_files << feature_report_dir / 'reopt' / "feature_report#{feature_report.id}_reopt_run_local.json"
      feature_report_timeseries_output_files << feature_report_dir / "feature_report#{feature_report.id}_timeseries.csv"

      scenario_report.add_feature_report(feature_report)
      feature_report_save_names << 'feature_report_reopt_local'
    end
    scenario_report.save 'test__/can_process_all_feature_reports'
    reopt_output_file = scenario_dir / 'test__' / 'scenario_report_reopt_local.json'
    reopt_assumptions_file = spec_files_dir / 'reopt_assumptions_with_wind_v3.json'

    # Act
    reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(scenario_report, reopt_assumptions_file, reopt_assumption_files, DEVELOPER_NREL_KEY)
    scenario_report = reopt_post_processor.run_scenario_report_features(scenario_report: scenario_report, reopt_output_files: reopt_output_files, feature_report_timeseries_csv_paths: feature_report_timeseries_output_files, save_names_feature_reports: feature_report_save_names, save_name_scenario_report: 'test__/scenario_report_reopt_local')

    # Assert
    expect((File.size(reopt_output_file).to_f / 1024) > 20)

    # Cleanup
    FileUtils.rm_rf(scenario_dir / '1' / 'reopt')
      FileUtils.rm_rf(scenario_dir / '2' / 'reopt')
      FileUtils.rm_rf(scenario_dir / '1' / 'feature_reports')
      FileUtils.rm_rf(scenario_dir / '2' / 'feature_reports')
      FileUtils.rm_rf(scenario_dir / 'reopt')
      FileUtils.rm_rf(scenario_dir / 'test__')
  end
end
