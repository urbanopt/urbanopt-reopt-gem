# REopt Lite Inputs Schema

The following shows the complete set of inputs to the REopt Lite API. You may refer to this in creating similarly formatted .json files containing alternatives to the defaults for optional parameters (i.e. escalation_pct, solar PV losses). The URBANopt REopt Gem will overwrite latitude, longitude, land_acres, roof_squarefeet, and loads_kw where possible from attributes of ScenarioReports and FeatureReports.

<ReoptSchema />

**Note:** The required parameters include *latitude*, *longitude*, *urdb_response* (or one of the following sets: *urdb_label*; *blended_monthly_rates_us_dollars_per_kwh*; *blended_annual_demand_charges_us_dollars_per_kw* **and** *blended_annual_rates_us_dollars_per_kwh*), and *loads_kw* (or one of the following sets: *doe_reference_name* **and** *annual_kwh*, *doe_reference_name* **and** *monthly_totals_kwh*). For an example, below is a minimally viable REopt Lite input:


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

<style type="text/css">
.content { max-width: 1200px !important; }
span.default { color: yellow !important; }
.description { color: #E0E0E0		 !important; }
</style>
