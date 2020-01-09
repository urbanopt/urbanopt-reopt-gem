# URBANopt REopt Gem

The **URBANopt REopt Gem** extends **URBANopt::Scenario::DefaultReports::ScenarioReport** and **URBANopt::Scenario::DefaultReports::FeatureReport** with the ability to derive cost-optimal distributed energy resource (DER) technology sizes and annual dispatch strageties via the [REopt Lite](https://reopt.nrel.gov/tool) decision support platform. 
REopt Lite is a technoeconomic model which leverages mixed integer linear programming to identify the cost-optimal sizing of solar PV, Wind, Storage and/or diesel generation given an electric load profile, a utility rate tariff and other technoeconomic parameters. See [https://developer.nrel.gov/docs/energy-optimization/reopt-v1/](https://developer.nrel.gov/docs/energy-optimization/reopt-v1/) for more detailed information on input parameters and default assumptions. 

See the [example project](https://github.com/urbanopt/urbanopt-example-geojson-reopt-project) for more infomation about usage of this gem.

<b>Note:</b> this module requires an API Key from the 
[NREL Developer Network](https://developer.nrel.gov/)

[RDoc Documentation](https://urbanopt.github.io/urbanopt-reopt-gem/)


## Installation

See [https://docs.urbanopt.net/installation/installation.html](https://docs.urbanopt.net/installation/installation.html) for instructions on prerequiste software, including: 
- Ruby 2.2.6
- Bundler 1.17.0
- OpenStudio 2.8.1

Add this line to your application's Gemfile:

```ruby
gem 'urbanopt-reopt'
```

And then execute:

    $ bundle install
    $ bundle update

Or install it yourself as:

    $ gem install 'urbanopt-reopt'

## Functionality

This gem is used to call the REopt Lite API on a Scenario Report or Feature Report to update the object's Distributed Generation attributes (including system financial and sizing metrics) as shown in an example below: 
```
	"distributed_generation": {
	      "lcc_us_dollars": 100000000.0,
	      "npv_us_dollars": 10000000.0,
	      "year_one_energy_cost_us_dollars": 7000000.0,
	      "year_one_demand_cost_us_dollars": 3000000.0,
	      "year_one_bill_us_dollars": 10000000.0,
	      "total_energy_cost_us_dollars": 70000000.0,
	      "solar_pv": {
	        "size_kw": 30000.0
	      },
	      "wind": {
	        "size_kw": 0.0
	      },
	      "generator": {
	        "size_kw": 0.0
	      },
	      "storage": {
	        "size_kw": 2000.0,
	        "size_kwh": 5000.0
	      }
	    }
```

Moreover, the following optimal dispatch fields are added to its timeseries CSV. Where no system component is recommended the dispatch will be all zero (i.e. if no solar PV is recommended ElectricityProduced:PV:Total will be always be zero)

|            output                        |  unit   |
| -----------------------------------------| ------- |
| ElectricityProduced:Total                | kWh     |
| Electricity:Load:Total                   | kWh     |
| Electricity:Grid:ToLoad                  | kWh     |
| Electricity:Grid:ToBattery               | kWh     |
| Electricity:Storage:ToLoad               | kWh     |
| Electricity:Storage:ToGrid               | kWh     |
| Electricity:Storage:StateOfCharge        | kWh     |
| ElectricityProduced:Generator:Total      | kWh     |
| ElectricityProduced:Generator:ToBattery  | kWh     |
| ElectricityProduced:Generator:ToLoad     | kWh     |
| ElectricityProduced:Generator:ToGrid     | kWh     |
| ElectricityProduced:PV:Total             | kWh     |
| ElectricityProduced:PV:ToBattery         | kWh     |
| ElectricityProduced:PV:ToLoad            | kWh     |
| ElectricityProduced:PV:ToGrid            | kWh     |
| ElectricityProduced:Wind:Total           | kWh     |
| ElectricityProduced:Wind:ToBattery       | kWh     |
| ElectricityProduced:Wind:ToLoad          | kWh     |
| ElectricityProduced:Wind:ToGrid          | kWh     |
    

The REopt Lite has default values for all non-required input parameters that are used unless the user specifies custom assumptions. See <StaticLink target="\_blank" href="https://developer.nrel.gov/docs/energy-optimization/reopt-v1/">https://developer.nrel.gov/docs/energy-optimization/reopt-v1/</StaticLink> for more detailed information on input parameters and default assumptions. 

<b>Note:</b> Required attributes for a REopt run include latitude and longitude. If no utility rate is specified in your REopt Lite assumption settings, then a constant default rate of $0.13 is assumed without demand charges. Also, by default, only solar PV and storage are considered in the analysis (i.e. Wind and Generators are excluded from consideration).



## Getting Started

The code below shows how to run the REopt API on a single Feature Report hash using this gem:

```ruby
require 'urbanopt/reopt'
#Load a Feature Report Hash
feature_reports_hash = {} # <insert a Feature Report hash here>

#Create a Feature Report
feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(feature_reports_hash)

#Specify a file name where REopt Lite results will be written in JSON format
reopt_output_file = File.join(feature_report.directory_name, 'feature_report_reopt_run1.json')

#Specify a file name where the new timeseries CSV will be written after REopt Lite has determined cost optimal dispatch
timeseries_output_file = File.join(feature_report.directory_name, 'feature_report_timeseries1.csv')

#Specify non-default REopt Lite assumptions, saved in JSON format, to be used in calling the API
reopt_assumptions_file = File.join(File.dirname(__FILE__), '../files/reopt_assumptions_basic.json')

#Create a REopt Lite Post Processor to call the API, note you will need a Developer.nrel.gov API key in this step
reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(nil, nil, nil, DEVELOPER_NREL_KEY)

#Call REopt Lite with the post processor to update the feature's distributed generation attributes and timeseries CSV.
updated_feature_report = reopt_post_processor.run_feature_report(feature_report,reopt_assumptions_file,reopt_output_file,timeseries_output_file)
    
```

More commonly, this gem can be used to run REopt a collection of features stored in a Scenario Report as show here:
```ruby
require 'urbanopt/reopt'
#Create a Scenario Report
scenario_report = URBANopt::Scenario::DefaultReports::ScenarioReport.new({:directory_name => File.join(File.dirname(__FILE__), '../run/example_scenario'), :timeseries_csv => {:path => File.join(File.dirname(__FILE__), '../run/example_scenario/timeseries.csv') }})

#Load Feature Reports into the Scenario Report     
(1..2).each do |i|
  feature_reports_path = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}/010_default_feature_reports/default_feature_reports.json")

  feature_reports_hash = nil
  File.open(feature_reports_path, 'r') do |file|
    feature_reports_hash = JSON.parse(file.read, symbolize_names: true)
  end

  feature_report = URBANopt::Scenario::DefaultReports::FeatureReport.new(feature_reports_hash)
  
  feature_report_dir = File.join(File.dirname(__FILE__), "../run/example_scenario/#{i}")
  feature_report.directory_name = feature_report_dir

  scenario_report.add_feature_report(feature_report)
end

#Specify non-default REopt Lite assumptions, saved in JSON format, to be used in calling the API
reopt_assumptions_file = File.join(File.dirname(__FILE__), '../files/reopt_assumptions_basic.json')

#Create a REopt Lite Post Processor to call the API, note you will need a Developer.nrel.gov API key in this step
reopt_post_processor = URBANopt::REopt::REoptPostProcessor.new(scenario_report, reopt_assumptions_file, nil, DEVELOPER_NREL_KEY)

#Call REopt Lite with the post processor once on the sceanrio's aggregated load to update the scenario's distributed generation attributes and timeseries CSV.
updated_scenario_report = reopt_post_processor.run_scenario_report(scenario_report)
    
```

## Testing

First, check out the repository (i.e. git clone this repo).

Next, obtain a developer.nrel.gov API key from the [NREL Developer Network](https://developer.nrel.gov/]). Copy and paste your key in to the _developer_nrel_key_._rb_ file then save the file:

    DEVELOPER_NREL_KEY = '<insert your key here>'

Finally, execute:

    $ bundle install
    $ bundle update    
    $ bundle exec rake


## Releasing

* Update change log
* Update version in `/lib/urbanopt/reopt/version.rb`
* Merge down to master
* run `rake release` from master
