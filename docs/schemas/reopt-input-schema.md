# REopt Lite Inputs Schema

The following shows the complete set of inputs to the REopt Lite API. You may refer to this in creating similarly formatted .json files containing alternatives to the defaults for optional parameters (i.e. escalation_pct, solar PV losses). The URBANopt REopt Gem will overwrite latitude, longitude, land_acres, roof_squarefeet, and loads_kw where possible from attributes of ScenarioReports and FeatureReports.

## Data Dictionary

<ReoptInputSchema />

## Required Inputs

The only required parameters are: *latitude*, *longitude*, *urdb_response* (or one of the following sets: *urdb_label*; *blended_monthly_rates_us_dollars_per_kwh*; *blended_annual_demand_charges_us_dollars_per_kw* **and** *blended_annual_rates_us_dollars_per_kwh*), and *loads_kw* (or one of the following sets: *doe_reference_name* **and** *annual_kwh*, *doe_reference_name* **and** *monthly_totals_kwh*). All non-required input parameters will be filled in with default values unless otherwise specified. For an example of a minimally viable REopt Lite input, see:


```
{	
	"Scenario": {
		"Site":{
			"latiude":45,
			"longitude":-110,
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

## Setting Custom Inputs

If you wish to use custom input parameters, other than default values, you have several options. 

* 1) Custom hashes, formatted as described above, can be directly paramaterized when invoking _reopt_json_from_scenario_report_ or _reopt_jsons_from_scenario_feature_reports_ from a **URBANopt::REopt::ScenarioReportAdapter**, or  _reopt_json_from_feature_report_ from a **URBANopt::REopt::FeatureReportAdapter**. 

* 2) Paths to custom hashes, formatted as described above and saved as JSON files in a common folder, can be specified in the input REopt Scenario CSV.


<style type="text/css">
.content { max-width: 1200px !important; }
span.default { color: yellow !important; }
.description { color: #E0E0E0		 !important; }
</style>