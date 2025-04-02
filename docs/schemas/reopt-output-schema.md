# REopt Lite Outputs Schema

When the gem calls the REopt Lite APUI it receives the following complete set of results described in the data dictionary below. Only those needed to update a Feature or Scenario Report's distributed_generation attribute set and timeseries CSV are pulled from the response and transferred to the Feature or Scenario Report. You may choose to modify the code to include more or less of the full REopt Lite response.

## Data Dictionary
<ReoptOutputSchema />

## Updated from the Data Dictionary

### Distributed Generation Attributes
The REopt Lite API updates the distributed_generation attributes of a Scenario or Feature Report as shown in an example below.

```
	"distributed_generation": {
	      "lcc": 100000000.0,
	      "npv": 10000000.0,
	      "year_one_energy_cost_before_tax": 7000000.0,
	      "year_one_demand_cost_before_tax": 3000000.0,
	      "year_one_bill_before_tax": 10000000.0,
	      "lifecycle_energy_cost_after_tax": 70000000.0,
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

### Timeseries CSV
REopt Lite API responses also map dispatches to the following columns in an updated timeseries CSV for a Feature or Scenario Report.

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

<style type="text/css">
.content { max-width: 1200px !important; }
span.default { color: yellow !important; }
.description { color: #E0E0E0		 !important; }
</style>
