# REopt Lite Inputs Schema

The following shows the complete set of inputs to the REopt Lite AP which is called internally by the REopt Gem. You may refer to the data dictionary below in creating similarly formatted .json files containing alternatives to the defaults for optional parameters (i.e. specific utility rate, installed cost assumptions, solar PV losses, ...). The URBANopt REopt Gem will overwrite latitude_deg, longitude_deg, land_acres, roof_squarefeet, and loads_kw where possible from attributes of a Scenario Report and FeatureReports.

## Data Dictionary

<ReoptInputSchema />

## Required Inputs

The only required parameters to the REopt Lite API (called internally by the gem) are:
- *latitude_deg*
- *longitude_deg*
- *urdb_response*
	Or one of the following sets: *urdb_label*; *blended_monthly_rates_us_dollars_per_kwh*; *blended_annual_demand_charges_us_dollars_per_kw* **and** *blended_annual_rates_us_dollars_per_kwh*

- *loads_kw*

	Or one of the following sets: *doe_reference_name* **and** *annual_kwh*, *doe_reference_name* **and** *monthly_totals_kwh*

The gem sources *latitude_deg*, *longitude_deg* and *loads_kw* from a Feature or Scenario Report directly. If no specific *urdb_response* or *urdb_label* is specified as an custom assumption (see below), then a constant rate of $0.13/kWh with no demand charge is provided by the gem as a default to the REopt API.

Otherwise, all non-required input parameters will be filled in with default values unless otherwise specified. For an example of a minimally viable REopt Lite input, see:


```
{
	"Scenario": {
		"Site":{
			"latiude_deg":45,
			"longitude_deg":-110,
			"ElectricTariff": {
				"urdb_label":"594976725457a37b1175d089"
			},
			"LoadProfile":{
				"doe_reference_name":"Hospital",
				"annual_kwh":1000000
			}
		}
	}
}
```

## Setting Custom Assumptions

If you wish to use custom input parameters, other than default values, you have a couple of options.

* 1) Custom hashes, formatted as described above, can be directly paramaterized when invoking _reopt_json_from_scenario_report_ or _reopt_jsons_from_scenario_feature_reports_ from a **URBANopt::REopt::ScenarioReportAdapter**, or  _reopt_json_from_feature_report_ from a **URBANopt::REopt::FeatureReportAdapter**.

* 2) Paths to custom hashes, formatted as described above and saved as JSON files in a common folder, can be specified in the input REopt Scenario CSV. See the [example project](https://github.com/TK-23/urbanopt-example-geojson-reopt-project.git) for more information on how to do this.


<style type="text/css">
.content { max-width: 1200px !important; }
span.default { color: yellow !important; }
.description { color: #E0E0E0		 !important; }
</style>
