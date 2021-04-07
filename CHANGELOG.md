# URBANopt REopt Gem

## Version 0.5.6

Date range: 3/12/21 - 4/7/21
* Fixes a bug that shifts REopt Lite timeseries data by 24 hours in **Feature Report** CSV's

## Version 0.5.5

Date range: 2/8/21 - 3/12/21
* Fixes a bug that shifts REopt Lite timeseries data by 24 hours in **Feature** and **Scenario Report** CSV's

## Version 0.5.4

Date range: 2/8/21 - 2/25/21
* Converts **Feature** and **Scenario Report** native timeseries data (i.e. load profile, optimized dispatches) to/from the specified **REopt Lite** time series resolution (defaulted to 1 timestep per hour), such that **OpenStudio** can be run at 10-minute intervals and **REopt Lite** at 1-hour or 15-minute intervals.


## Version 0.5.3

Date range: 1/21/21 - 2/8/21
* **Storage** should not be considered in total production CSV series
* **coincident_peak_load_charge_us_dollars_per_kw** should be defaulted to 0

## Version 0.5.2

Date range: 1/08/21 - 1/21/21
* Adds default coincident peak load (top 100 hours) if not specified in assumptions file to a REopt Lite post
* Specifies coincident peak price as 0 in test assumptions file to turn it off
* Allows default roof area, land area and timesteps per hour to be overwritten by assumptions file when creating a REopt Lite post


## Version 0.5.1

Date range: 12/11/20 - 1/08/21

* Extend polling time for resilience results
* Do not error out if there are no resilience results
* Handle renamed available_roof_area_sqft parameter (had been available_roof_area)


## Version 0.5.0

Date range: 11/13/20 - 12/11/20

* Updates to support OpenStudio 3.1  

 
## Version 0.4.1

Date range: 9/23/20 - 11/12/20

* PR template now automatically closes issue on merge
* Remove unnecessary require statement
* Reporting bugfix
* Working with reporting gem updates


## Version 0.4.0

Date range: 6/5/20 - 9/22/20

* Changes to support the new reporting gem
* Parsing additional results from the REopt Lite API: 
  - lcc_bau_us_dollars
  - year_one_energy_cost_bau_us_dollars
  - year_one_demand_cost_bau_us_dollars
  - year_one_bill_bau_us_dollars
  - total_energy_cost_bau_us_dollars
  - total_demand_cost_us_dollars
  - total_demand_cost_bau_us_dollars
* Makes separate calls to the REopt Lite API for new resilience statistics:
  - resilience_hours_min
  - resilience_hours_max
  - resilience_hours_avg
  - probs_of_surviving
  - probs_of_surviving_by_month
  - probs_of_surviving_by_hour_of_the_day


## Version 0.3.0

* Updating to support OpenStudio 3.0 and Ruby 2.5

## Version 0.2.1 
* Corrects code checking PV size that fails on multi PV
* Corrects parsing of site energy at timesteps other than 1 per hour


## Version 0.2.0 

* Handles multiple PV systems in the REopt Lite assumptions
* Changes REoptPostProcessor run_scenario and run_scenario_features methods to save feature and scenario reports with custom names
* Parses date from timeseries CSV when creating load profile for REopt job and when parsing optimized results
* Renames REopt timeseries CSV columns to include 'REopt' and units


## Version 0.1.0 

* Initial release of URBANopt REopt Gem. 
